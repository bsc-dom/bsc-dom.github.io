import threading
import traceback

from dataclay import DataClayObject, dclayMethod
"""
City Knowledge Base: collection of Events Snapshots
"""
class DKB(DataClayObject):
    """
    @ClassField kb dict<int, test_namespace.elastic.Snapshot>
    @ClassField objects dict<str, test_namespace.elastic.DetectedObject>

    @dclayImport threading
    @dclayImport traceback
    """
    @dclayMethod()
    def __init__(self):
        self.kb = dict()
        self.objects = dict()

    @dclayMethod(event_snp='test_namespace.elastic.Snapshot')
    def add_events_snapshot(self, event_snp):
        self.kb[event_snp.timestamp] = event_snp

    @dclayMethod(obj='test_namespace.elastic.DetectedObject')
    def add_object(self, obj):
        id_object = obj.id_object
        if id_object not in self.objects:
            self.objects[id_object] = obj

    @dclayMethod(object_id='str', object_class='str', x='int', y='int', w='int', h='int', timestamp='int',
                 return_='test_namespace.elastic.DetectedObject')
    def get_or_create(self, object_id: str, object_class: str, x: int, y: int, w: int, h: int, timestamp: int):
        if not hasattr(self, "global_lock") or self.global_lock is None:
            self.global_lock = threading.Lock()
        with self.global_lock:
            if object_id not in self.objects:
                obj = DetectedObject(object_id, object_class, timestamp, x, y, w, h)
                self.objects[object_id] = obj
            return self.objects[object_id]

    @dclayMethod(timestamp='int', unfederate_objs='bool')
    def remove_old_objects_and_snapshots(self, timestamp: int, unfederate_objs: bool):
        if not hasattr(self, "global_lock") or self.global_lock is None:
            self.global_lock = threading.Lock()
        for snap_timestamp in list(self.kb.keys()):
            if snap_timestamp < timestamp:
                snap = self.kb[snap_timestamp]
                print(f"******* Deleting sanpshot {snap.get_object_id()}")
                snap.delete(unfederate_objs)
                del self.kb[snap_timestamp]
        for object_id in list(self.objects.keys()):
            obj = self.objects[object_id]
            if obj.timestamp < timestamp:
                with self.global_lock:
                    print(f"******* Deleting object {obj.get_object_id()}")
                    obj.delete(unfederate_objs)
                    del self.objects[object_id]

    """
    @dclayMethod(return_="dict<str, anything>")
    def __getstate__(self):
        return {"kb": self.kb, "objects": self.objects, "objects_timestamps": self.objects_timestamps}

    @dclayMethod(state="dict<str, anything>")
    def __setstate__(self, state):
        self.kb = state["kb"]
        self.objects = state["objects"]
        self.objects_timestamps = state["objects_timestamps"]
        self.global_lock = threading.Lock()
    """

"""
Snapshot: List of the objects detected in an snapshot. Each object
contains a list of events (last event for current snapshot and events history).
"""
class Snapshot(DataClayObject):
    """
    @ClassField events list<test_namespace.elastic.Event>
    @ClassField snap_alias str
    @ClassField timestamp int
    """

    @dclayMethod(alias='str')
    def __init__(self, alias):
        self.events = list()
        self.snap_alias = alias
        self.timestamp = 0

    @dclayMethod(num_events_per_obj='int', id_object='str', obj_class='str',
                 x='int', y='int', w='int',h='int', vel_pred='anything', yaw_pred='anything',
                 lon='anything', lat='anything',
                 kb='test_namespace.elastic.DKB')
    def add_events_from_trackers(self, num_events_per_obj: int, id_object: str, obj_class: str, x: int, y: int, w: int, h: int, vel_pred: float, yaw_pred: float,
                                 lon: float, lat: float, kb):
        import uuid
        for i in range(num_events_per_obj):
            obj = kb.get_or_create(id_object, obj_class, x, y, w, h, self.timestamp + i)
            event = Event(uuid.uuid4().int, obj, self.timestamp + i, vel_pred, yaw_pred, float(lon), float(lat))
            obj.add_event(event)
            self.events.append(event)

    @dclayMethod(unfederate_objs='bool')
    def delete(self, unfederate_objs: bool):
        if unfederate_objs:
            self.unfederate(recursive=False)
        self.session_detach()
        self.events.clear()

    @dclayMethod(return_='str')
    def __repr__(self):
        return f"Events Snapshot: \n\tevents: {self.events}, \n\tsnap_alias: " \
               f"{self.snap_alias}, timestamp: {self.timestamp}"


    @dclayMethod()
    def when_federated(self):
        try:
            kb = DKB.get_by_alias("DKB")
            kb.add_events_snapshot(self)
            ## add all events to objects
            for event in self.events:
                obj = event.detected_object
                obj.add_event(event)
                kb.add_object(obj)

        except Exception:
            traceback.print_exc()

"""
Object: Vehicle or Pedestrian detected
        Objects are classified by type: Pedestrian, Bicycle, Car, Track, ...
        Only if it is not a pedestrian, the values speed and yaw are set.
"""
class DetectedObject(DataClayObject):
    """
    @ClassField id_object str
    @ClassField timestamp int
    @ClassField type str
    @ClassField events_history dict<int, test_namespace.elastic.Event>
    @ClassField pixel_x int
    @ClassField pixel_y int
    @ClassField pixel_w int
    @ClassField pixel_h int
    """

    @dclayMethod(id_object='str', obj_type='str', timestamp='int', x='int', y='int', w='int', h='int')
    def __init__(self, id_object: str, obj_type: str, timestamp: int, x: int, y: int, w: int, h: int):
        self.id_object = id_object
        self.type = obj_type
        self.events_history = dict()
        self.timestamp = 0
        self.pixel_x = x
        self.pixel_y = y
        self.pixel_w = w
        self.pixel_h = h

    @dclayMethod(event='test_namespace.elastic.Event')
    def add_event(self, event):
        # self.events_history.append(event)
        self.events_history[event.timestamp] = event
        cur_ts = event.timestamp
        if cur_ts > self.timestamp:
            self.timestamp = cur_ts

    @dclayMethod(unfederate_objs='bool')
    def delete(self, unfederate_objs: bool):
        for event in self.events_history.values():
            print(f"******* Deleting event {event.get_object_id()}")
            event.delete()
        if unfederate_objs:
            self.unfederate(recursive=True)
        self.events_history.clear()
        self.session_detach()
"""
Event: Instantiation of an Object for a given position and time.
"""
class Event(DataClayObject):
    """
    @ClassField id_event int
    @ClassField detected_object test_namespace.elastic.DetectedObject
    @ClassField timestamp int
    @ClassField speed anything
    @ClassField yaw anything
    @ClassField longitude_pos anything
    @ClassField latitude_pos anything
    """
    @dclayMethod(id_event='int', detected_object='test_namespace.elastic.DetectedObject', timestamp='int', speed='anything',
                 yaw='anything', longitude_pos='anything', latitude_pos='anything')
    def __init__(self, id_event: int, detected_object, timestamp: int, speed: float, yaw: float, longitude_pos: float, latitude_pos: float):
        self.id_event = id_event
        #FIXME: gc distributed bug
        self.detected_object = detected_object
        self.timestamp = timestamp
        self.speed = speed
        self.yaw = yaw
        self.longitude_pos = longitude_pos
        self.latitude_pos = latitude_pos

    @dclayMethod()
    def delete(self):
        self.session_detach()
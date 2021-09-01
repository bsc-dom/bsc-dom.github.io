from dataclay import DataClayObject, dclayMethod
class Person(DataClayObject):
    """
    @ClassField name str
    @ClassField age int
    """
    @dclayMethod(name='str', age='int')
    def __init__(self, name: str, age: int):
        self.name = name
        self.age = age

    @dclayMethod(return_="str")
    def getName(self):
        return self.name

    @dclayMethod(name="str")
    def setName(self, name: str):
        self.name = name

    @dclayMethod(return_="int")
    def getAge(self):
        return self.age

    @dclayMethod(age="int")
    def setAge(self, age: int):
        self.age = age

    @dclayMethod(execution_environment_id='anything', return_='bool')
    def replicaSourceIs(self, execution_environment_id):
        return self.get_origin_location() == execution_environment_id

    @dclayMethod(execution_environment_id='anything', return_='bool')
    def replicaDestIncludes(self, execution_environment_id):
        return execution_environment_id in self.get_replica_locations()

    @dclayMethod(return_="str")
    def __str__(self):
        return " - Name: %s, age: %d" % (self.name, self.age)

class People(DataClayObject):
    """
    @ClassField people list<test_namespace.classes.Person>
    """
    @dclayMethod()
    def __init__(self):
        self.people = list()

    @dclayMethod(new_person="test_namespace.classes.Person")
    def add(self, new_person):
        self.people.append(new_person)

    @dclayMethod(idx="int")
    def get(self, idx: int):
        return self.people[idx]

    @dclayMethod(return_="str")
    def __str__(self):
        result = ["People:"]
        for p in self.people:
            result.append(str(p))
        return "\n".join(result)

class SyncObject(DataClayObject):
    """
    @dclayReplication(afterUpdate='synchronize', inMaster='False')
    @ClassField name str
    @dclayReplication(afterUpdate='synchronize', inMaster='False')
    @ClassField value int
    """
    @dclayMethod(name='str', value='int')
    def __init__(self, name: str, value: int):
        self.name = name
        self.value = value

    @dclayMethod(return_="str")
    def getName(self):
        return self.name

    @dclayMethod(name="str")
    def setName(self, name: str):
        self.name = name

    @dclayMethod(return_="int")
    def getValue(self):
        return self.value

    @dclayMethod(value="int")
    def setValue(self, value: int):
        self.value = value

    @dclayMethod(execution_environment_id='anything', return_='bool')
    def replicaSourceIs(self, execution_environment_id):
        return self.get_origin_location() == execution_environment_id

    @dclayMethod(execution_environment_id='anything', return_='bool')
    def replicaDestIncludes(self, execution_environment_id):
        return execution_environment_id in self.get_replica_locations()

    @dclayMethod(return_="str")
    def __str__(self):
        return " - Name: %s, value: %d" % (self.name, self.value)

class NodeA(DataClayObject):
    """
    @ClassField node_b test_namespace.classes.NodeB
    """

    @dclayMethod()
    def __init__(self):
        self.node_b = None

    @dclayMethod(return_="test_namespace.classes.NodeB")
    def getNodeB(self):
        return self.node_b

    @dclayMethod(node_b="test_namespace.classes.NodeB")
    def setNodeB(self, node_b):
        self.node_b = node_b

class NodeB(DataClayObject):
    """
    @ClassField node_a test_namespace.classes.NodeA
    """

    @dclayMethod()
    def __init__(self):
        self.node_a = None

    @dclayMethod(return_="test_namespace.classes.NodeA")
    def getNodeA(self):
        return self.node_a

    @dclayMethod(node_a="test_namespace.classes.NodeA")
    def setNodeA(self, node_a):
        self.node_a = node_a

class BigObject(DataClayObject):
    """
    @ClassField obj_bytes anything
    """
    @dclayMethod()
    def __init__(self):
        import os
        self.obj_bytes = bytearray(os.urandom(1000000))

class LittleObject(DataClayObject):
    """
    @ClassField obj_bytes anything
    """
    @dclayMethod()
    def __init__(self):
        import os
        self.obj_bytes = bytearray(os.urandom(100))

class LotsOfObjects(DataClayObject):
    """
    @ClassField little_objs list<test_namespace.classes.LittleObject>
    """
    @dclayMethod()
    def __init__(self):
        self.little_objs = list()
        for i in range(100):
            self.little_objs.append(LittleObject())

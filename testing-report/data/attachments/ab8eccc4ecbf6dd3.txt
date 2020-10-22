package model;

import es.bsc.dataclay.DataClayObject;

public class Person extends DataClayObject implements Person_Stub {
	String name;
	int age;

	public Person(String newName, int newAge) throws Exception {
		name = newName;
		age = newAge;
	}

	public String getName() {
		return name;
	}

	public int getAge() {
		return age;
	}
}

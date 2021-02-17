package model;

import es.bsc.dataclay.DataClayObject;

import java.util.ArrayList;

public class People extends DataClayObject implements People_Stub {
	private ArrayList<Person_Stub> people;

	public People() {
		people = new ArrayList<>();
	}

	public String toString() {
		String result = "People: \n";
		for (Person_Stub p : people) {
			result += " - Name: " + p.getName();
			result += " Age: " + p.getAge() + "\n";
		}
		return result;
	}

	@Override
	public void add(Person_Stub newPerson) {
		people.add(newPerson);
	}
}

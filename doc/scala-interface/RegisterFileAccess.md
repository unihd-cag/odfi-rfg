Register File Access API
===========================

# Introduction

The Register file access API allows accessing registers/rams/fields of a RegisterFile definition
by using a Scala Based programming interface.

References to the register file elements are fetched using a string format mirroring the structure of the loaded register file

The API provides the following functionalities while accessing a register file:

- Separate Hardware access implementation layer to allow supproting various hardware interfaces (different driver types, remote communication etc...)
- Multiple hardware targets support, to allow one user interface to access different hardwares (located on the same machine or not)
	- One loaded Registerfile definition can issue read/writes to different hardware devices, for performance reason.
- A transaction mechanism used for target node selection, that allows classical commit/rollback management of values
- A set of functions to gather data models like graphs or tables, which can then be saved or viewed depending on the supporting software

# Hardware interface layer

The Hardware interface that actually issues the reads and writes to a particular device is only specified by this library, but no specific implementation is provided.

The supporting software that uses this register file access library is responsible for providing this implementation and selecting it at runtime

## Device interface to be implemented

The Device interface contains two methods to be implemented:

- writeRegister( nodeId: Int, address : Long , value : Long)
	
	Writes a register value at a specific device and address on the device

- readRegister( nodeId : Int, address : Long) : Long

	Reads a register value at a specific device and address

The "nodeId" value is required as an idenfifier to  potentially access a device located on a network.
In the case of an implementation only accessing a specific unique device, this parameter can be ignored


## Interface selection at runtime

Once a Hardware device interface has been implemented, it must be selected before any registerfile operations can happen

This is easily done, by setting the selectedDevice field on the Device singleton:

	Device.selectedDevice = new MyHardwareInterface


# Transaction mechanism

The role of the transactions in this library is connected to the use of the OOXOO XML parsing library.

In a few words, the XML representation of the Registerfile is modeled by the definition of a set of Classes like Register, Field, RamBlock etc..
The OOXOO library, when parsing the XML definition, creates instances of those classes, that are linked with each other to mirror the XML structure.

## Register access requirements

As seen previously, the register file interface needs two main information pieces to be able to issue read/writes:

- The target node
- The target register

This could be implementing the following way:

- The Register class has write/read methods, that issue the request to the Device object
- The target node can be configured in a singleton (remember we only want one registerfile definition for all possible nodes), stored in a map keyed by the current Thread to allow parallel  execution.

However, the main concept behind the OOXOO library, is to try to use object chaining instead of method overloading to offer multiple functionalities.
In other words, instead of adding a method to the Register class to perform read/write, we want to chain it another object (or some other objects) that will take care of device handling

This makes the interfaces way more flexibel, by avoiding common datatypes, but expose the interfaces to specification glitches.



## The transaction buffer usage

TODO


# Multiple node support

The support for multiple node is trivial since we have seen that the target node information has to be extracted from Transaction context.

For this purpose, the target node must be an instance of an object implementing the RegisterFileHost class, and be the initator of the transaction

	var registerFileNode = ... // A class instance provided by supporting software
	Transaction(registerFileNode)

	// Here we are in a valid register file transaction

	Transaction().start // Activate values caching

	Transaction().commit // Write values

	Transaction().discard // Close transaction for current Thread


# API Reference


## Search String

- Group: "path/to/regroot"

	Examples:

		group.group("extoll_rf/info_rf")
		registerFile.group("path/to/regroot") // The RegisterFile class inherits Group

- Register: "path/to/register"

	Examples:

		group.register("extoll_rf/info_rf/node")

- Register Field: "path/to/register.field"

	Examples:

		group.field("extoll_rf/info_rf/node.id")
	

## Select Node Target

	// Enclosing class must mix the RegisterFileLanguage trait

	var registerFileHost = ...
	on(registerFileHost) {

		// Transaction gets started and commited at the end of this code block by the on() method

	}


## Write


	write(value) into "searchstring"

value is a Long in scala/java syntax:

	write(80)   into "searchString" // 80 decimal
	write(0x80) into "searchString" // 80 hex



## Read

	var value = read("search/string")

## Poll

Sometimes it is required to poll on a value to synchronise with the hardware
The poll function will perform read on the provided register/field, until a specific value is matched.
If the value is not matched after the specified delay, an exception is thrown as an error
	

	poll on "search/string" until ( Long => Boolean) during timeInms now

with:

- (Long => Boolean) is a function the returns true/false if the provided read Long value is the exepected one or not
- timeInms is a long value representing the time to wait for the check function return true, if overdued, a time out exception is thrown
- the now keyword triggers execution of the polling, and must be used as last call.

### Simple poll
	
	// Poll and get the value back if successful
	var readValue = (poll on "path" until { value => value == 1} during 500 now).resultValue

	// Prepare poll action and run it later
	var pollAction = poll on "path" until {value => value ==1} during 500

	pollAction now


### Poll with value match

	(poll on "path" until {value => value == 1 || value == 2} during 500 now) match {
		case Poll(1) => 
			println("Polled value was 1")
		case Poll(2) => 
			println("Polled value was 2")
	}

### Catch poll fail

	try {
		(poll on "path" until {value => value == 1 || value == 2} during 500 now)
	} catch {
		case e : Throwable => 

			println(s"Polling Failed here")
	}

# Data Reference

The Data interface is a set of functions that can be called when using the register file access api to gather somes datas

Those functions are provided by the Graph and table modles of the VUI library, but this library does not define how to handle thos datas.

It is the role of the supporting software to decide where those results have to endup (on a GUI, send back to a network requestor etc...)

## Graphs

### Time Data set

A Time dataset is a (key,value) set for a graph, whose keys are automatically set to the current system timestamp.
This is convienient to sample the evolution of a value over time
	
	// Create data set
	var dataSet = timeDataset("name of our dataset")

	// Do something here

	// Save a value from a read, could also be a variable
	dataSet <= read("register value")

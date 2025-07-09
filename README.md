[![CI](https://github.com/Ortus-Solutions/ServiceBusSDK/workflows/CI/badge.svg)](https://github.com/Ortus-Solutions/ServiceBusSDK/actions)


# Welcome to the ServiceBusSDK Module

Azure Service Bus is a messaging as a service platform which supports queues and topics.  

This library is a wrapper for CFML/ColdFusion apps to be able to interact with Azure Service Bus via the Java SDK.  

## LICENSE

Apache License, Version 2.0.

## IMPORTANT LINKS

- Source: https://github.com/Ortus-Solutions/ServiceBusSDK
- Issues: https://ortussolutions.atlassian.net/browse/BOX

## SYSTEM REQUIREMENTS

- Lucee 5+
- Adobe 2021+
- BoxLang 1+


## Installation

Install into your modules folder using the `box` cli to install

```bash
box install ServiceBusSDK
```
You are responsible for loading the jars into your application.
If this is a CFML web app, you can add this to your `Application.cfc`

```js
this.javaSettings = {
	loadPaths = directorylist( expandPath( '/modules/ServiceBusSDK/lib' ), true, 'array', '*jar' ),
	loadColdFusionClassPath = true,
	reloadOnChange = false
};
```

Or if you are using this module from the CLI, you can load the jars in a task runner or custom command in CommandBox prior to using the module like so:
```js
classLoad( 'expandPath( '/ServiceBusSDK/lib' )' );
```

# Usage

This module wraps and _simplifies_ the java SDK.  There are only a few CFCs for you to worry about, and while not 100% of the Java SDK functionality is exposed, all the major functions are here.

* Send messages
* Receive messages directly
* Start a multi-threaded processor to consume messages

Here are the major CFCs you need to know about:

* **Client** - Singleton that represents the main ServiceBus client.  This class doesn't contain any underlying connections, but it does track the receivers and processors it creates.  Shutting down the client will also shut down all receivers and processors. The client will automatically shut itself down via an interceptor when ColdBox is reloaded or the CLI is exited.
* **Sender** - Transient used to send messages.  Feel free to re-use this class for multiple messages.  Don't forget to shut down any senders when you are done with them to release TCP connections.
* **Receiver** - Transient used to manually receive one or messages.  Feel free to re-use this class for multiple messages.  Don't forget to shut down any receivers when you are done with them to release TCP connections.
* **Processor** - Transient that starts up one or more background processing threads to process messages as they come into a queue or topic.  Don't forget to shut down any processors after you stop them to release TCP connections.


## Client

Create this only once and re-use over the life of your app.  The CFC is marked as a singleton, so if you are using WireBox to access it, you don't need to manually cache it anywhere.
Simply inject it wherever you need and use it.  It is very important to call the `shutdown()` method to release the connection when your app is shutting down or reiniting.

```js
wirebox.getInstance( 'Client@ServiceBusSDK' );
```
or 

```js
property name='client' inject='Client@ServiceBusSDK';
```

You can configure the client with the following module settings

```js
moduleSettings = {
			fullyQualifiedNamespace : '',
			credentials : {
				type : 'connectionString', // connectionString, default, ClientSecret, ClientCertificate
				connectionString : '',
				authorityHost : '',
				tenantId : '',
				clientId : '',
				clientSecret : '',
				pemCertificatePath : '',
				pfxCertificatePath : '',
				certificatePassword : '',
				maxRetry : 3,
				tokenRefreshOffsetSeconds : 0,
				enablePersistentCache : false
			}
		}
};
```


### Credential Types

- type : "connectionString"
	- connectionString
- type : "default"
	- authorityHost
	- tenantId
	- maxRetry
	- tokenRefreshOffsetSeconds
- type : "ClientSecret"
	- authorityHost
	- tenantId
	- clientId
	- clientSecret
	- maxRetry
	- tokenRefreshOffsetSeconds
	- enablePersistentCache
- type : "ClientCertificate"
	- authorityHost
	- tenantId
	- clientId
	- pemCertificatePath (mutex with pfxCertificatePath)
	- pfxCertificatePath (mutex with pemCertificatePath)
	- certificatePassword (only used for pfx)
	- maxRetry
	- tokenRefreshOffsetSeconds
	- enablePersistentCache

## Sender

To send a message, build a sender and use it.

```js

var sender = client.buildSender( queueName='new-orders' );

sender.sendMessage( { orderId=12345, customerName='John Doe' } );

sender.shutdown();
```

Call `sendMessage()` as many times you like on the same sender.  

### Sender options

These are the arguments you can pass to the `client.buildSender()` method.

* *String* `queueName`
* *String* `topicName`
* *Boolean* `async` - Sends async
* *String* `fullyQualifiedNamespace` - Defaults to the module setting

## Receiver

Use the receiver to peek at a queue or manually receive a message in the current thread.
Peeking returns right away and doesn't allow you to complete the message.  It remains in the queue.

These are the arguments to can pass to the `client.buildReceiver()` method.

* *String* `queueName`
* *String* `topicName`
* *Boolean* `autoComplete`
* *Numeric* `prefetchCount`
* *String* `receiveMode` - PEEK_LOCK, or RECEIVE_AND_DELETE
* *Boolean* `async` - returns an async message which blocks when you call the first method on it
* *String* `fullyQualifiedNamespace` - Defaults to the moudle setting

```js
var receiver = client.buildReceiver( queueName='new-orders' );

var message = receiver.peekMessage();

// null if no messages are found
if( !isNull( message ) ) {
	writeoutput( message.getBody() )
}

receiver.shutdown();
```

Or get an array of messages up to a max count.  


```js
var receiver = client.buildReceiver( queueName='new-orders' );

var messages = receiver.peekMessages( 10 );

message.each( m => writeoutput( m.getBody() ) );

receiver.shutdown();
```

Peeking is just for seeing what's in a queue or topic.  To actually process messages, use the `receiveMessage()` method.
Unlike peeking, the receive methods will BLOCK until a message is available, or until the timeout you supply is reached.  
If you don't supply a timeout, the method will block forever until a message is available.

```js
var receiver = client.buildReceiver( queueName='new-orders' );

// wait up to 2 seconds for a message
var message = receiver.receiveMessage( 2 );

// null if no messages are found
if( !isNull( message ) ) {
	writeoutput( message.getBody() )
}
```

If the receive mode is `PEEK_LOCK`, then you must manually `complete()`, `abandon()`, `defer()`, or `deadletter()` each message.
```js
if( processingSuccess ) {
	message.complete();
} else {
	message.abdondon();
}

receiver.shutdown();
```

Receive multiple messages at a time and get an array of messages back like so:

```js
var receiver = sbClient.buildReceiver( queueName='new-orders' );

// Get up to 10 messages, waiting no longer than 2 seconds
var messages = receiver.receiveMessages( 10, 2 );

message.each( m => writeoutput( m.getBody() ) );

receiver.shutdown();
```

## Processor

A processor is a special type of receiver which spins up one or more threads in the background which process messages as they come in.  You must start/stop a processor. 
You can create a processor on app startup which simply runs in the background so long as the app is running.

These are the arguments to can pass to the `client.buildProcessor()` method.

* *String* `queueName`
* *String* `topicName`
* *Boolean* `autoComplete` -- same as `buildReceiver()`
* *Numeric* `prefetchCount`
* *String* `receiveMode` -- same as `buildReceiver()`
* *Numeric* `maxConcurrentCalls` - number of processor threads
* *Function* `onMessage` - A function which receives the message object
* *Function* `onError` - A function which receives the exception, entityPath, errorSource, and fullyQualifiedNamespace
* *boolean* `autoStart` - True starts the processor right away
* *String* `fullyQualifiedNamespace` - default to module settings

You can fire up your processor threads like so:

```js
var processor = client.buildProcessor(
	queueName='new-orders',
	onMessage=function( message ){
		// Put your logic here to process each message
		createObject('java', 'java.lang.System').out.println( 'Received message: ' & serializeJSON( message.getBody() ) );
	},
	maxConcurrentCalls=10
);

processor.start();
// Wait for it to process some messages
sleep( 1000 );
processor.stop();
```


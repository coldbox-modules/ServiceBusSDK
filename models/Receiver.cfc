/**
*********************************************************************************
* Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* Service Bus receiver.  This class is used to get message(s) from a queue or a topic.
* It wraps an underlying connection and is thread safe.  Feel free to re-use it
* for the duration of your application.  It can only receive one message at a time,
* so for high concurrency, you can can create multiple receivers, or use a processor.
*
* If you don't the shutdown() method when you're done using it, you'll leave orphaned connections open.
*/
component accessors=true ThreadSafe {

	// DI
	property name="wirebox" inject="wirebox";
	property name="log" inject="logbox:logger:{this}";


	property name="SBClient";
	property name="jMonoClass";
	property name="ID";
	// https://javadoc.io/static/com.azure/azure-messaging-servicebus/7.17.12/com/azure/messaging/servicebus/ServiceBusReceiverClient.html
	property name="jReceiver";
	property name="async";

	/**
	 * Constructor
	 */
	function init(  Client SBClient,  Struct receiverProperties ) {
		setSBClient( arguments.SBClient );
		setID( createUUID() );
		setJMonoClass( createObject( 'java', 'reactor.core.publisher.Mono' ) );


		if( receiverProperties.queueName.isEmpty() && receiverProperties.topicName.isEmpty() ) {
			throw( message='You must specify either a queueName or topicName to build a receiver.' );
		}
		var receiverBuilder = SBClient.newClientBuilder( receiverProperties.fullyQualifiedNamespace )
			.receiver();
			
		if( !receiverProperties.queueName.isEmpty() ) {
			receiverBuilder.queueName( receiverProperties.queueName );
		} else if( !receiverProperties.topicName.isEmpty() ) {
			receiverBuilder.topicName( receiverProperties.topicName );
		}

		if( !isNull( receiverProperties.prefetchCount ) && isNumeric( receiverProperties.prefetchCount ) ) {
			receiverBuilder.prefetchCount( receiverProperties.prefetchCount );
		}

		receiverBuilder.receiveMode( createObject( 'java', 'com.azure.messaging.servicebus.models.ServiceBusReceiveMode' ).valueOf( receiverProperties.receiveMode.ucase() ) );

		// if we are in RECEIVE_AND_DELETE mode, we cannot auto complete messages
		if( !receiverProperties.autoComplete || receiverProperties.receiveMode == 'RECEIVE_AND_DELETE' ) {
			receiverBuilder.disableAutoComplete();
		}
		
		setAsync( receiverProperties.async );

		if( receiverProperties.async ) {
			setJReceiver( receiverBuilder.buildAsyncClient() );
		} else {
			setJReceiver( receiverBuilder.buildClient() );
		}

		return this;
	}

	/**
	 * Peek at a message.  This returns a message or null immediatley without blocking.
	 * If this is an async receiver, an async message will be returned that will block when the first method is called.
	 * This does not place any locks on the message, nor does it allow you to complete, abandon, dead letter, or defer the message.
	 * Only use this for inspecting messages, not for processing them.
	 * 
	 * @sequenceNumber The sequence number of the message to peek at.  If not provided, it will peek at the next message.
	 * @return A message or null if no message is available.
	 */
	function peekMessage( numeric sequenceNumber ) {
		if( !isNull( arguments.sequenceNumber ) ) {
			var result = jReceiver.peekMessage( arguments.sequenceNumber );
		} else {
			var result = jReceiver.peekMessage();
		}
		if( isNull( result ) ) {
			return null;
		}
		if( getAsync() ) {
			return wirebox.getInstance( 'AsyncReceiverMessage@ServiceBusSDK', { receiver : this,  mono : result } );
		} else {
			return wirebox.getInstance( 'ReceiverMessage@ServiceBusSDK', { receiver : this,  jMessage : result } );
		}
	}

	/**
	 * Peek at a list of messages.  This returns a list of messages or an empty list immediatley without blocking.
	 * If this is an async receiver, async messages will be returned that will block when the first method is called.
	 * This does not place any locks on the message, nor does it allow you to complete, abandon, dead letter, or defer the message.
	 * Only use this for inspecting messages, not for processing them.
	 * 
	 * @maxMessages The maximum number of messages to peek at.  Defaults to 1.
	 * @sequenceNumber The sequence number of the message to peek at.  If not provided, it will peek at the next message.
	 * 
	 * @return A list of messages or an empty list if no messages are available.
	 */
	function peekMessages( required numeric maxMessages=1, numeric sequenceNumber ) {
		if( !isNull( arguments.sequenceNumber ) ) {
			var result = jReceiver.peekMessages( arguments.maxMessages, arguments.sequenceNumber );
		} else {
			var result = jReceiver.peekMessages( arguments.maxMessages );
		}
		
		if( getAsync() ) {
			var listMonos = result.map( getJJustFunction() ).collectList().block();
			return arrayMap( listMonos, (i)=> {
					return wirebox.getInstance( 'AsyncReceiverMessage@ServiceBusSDK', { receiver : this,  mono : i } );
			} );
		} else {
			var listMonos = result.stream().toList();
			return arrayMap( listMonos, (i)=> {
					return wirebox.getInstance( 'ReceiverMessage@ServiceBusSDK', { receiver : this,  jMessage : i } );
			} );
		}
	}

	/**
	 * Receive a message.  This will block until a message is available or the max wait time is reached.
	 * If this is an async receiver, an async message will be returned that will block when the first method is called.
	 * 
	 * Whether or not you can complete, abandon, dead letter, or defer the message depends on the receive mode of the receiver.
	 * 
	 * @maxWaitTimeSeconds The maximum time to wait for a message in seconds.  Defaults to 0 (no wait).
	 * 
	 * @return A message or null if no message is available.
	 */
	function receiveMessage( numeric maxWaitTimeSeconds=0) {
		var result = receiveMessages( 1, arguments.maxWaitTimeSeconds );
		if( result.len() == 0 ) {
			return null;
		}
		return result[1];
	}

	/**
	 * Receive a list of messages.  This will block until the max number of messages is received or the max wait time is reached.
	 * Do not use this method on an async receiver. If you want to receive multiple messages asynchronously, use a processor instead.
	 * 
	 * Whether or not you can complete, abandon, dead letter, or defer the messages depends on the receive mode of the receiver.
	 * 
	 * @maxMessages The maximum number of messages to receive.  Defaults to 1.
	 * @maxWaitTimeSeconds The maximum time to wait for messages in seconds.  Defaults to 0 (no wait).
	 * 
	 * @return A list of messages or an empty list if no messages are available.
	 */
	function receiveMessages( required numeric maxMessages=1, numeric maxWaitTimeSeconds=0 ) {
		if( getAsync() ) {
			// We COULD support this, but with CF's poor Java interop, it would be cumbersome, and honeslty a processor is a better fit.
			throw( message='Receiving Messages async not supported.  Use a processor instead.' );
		}
		if( arguments.maxWaitTimeSeconds > 0 ) {
			var result = jReceiver.receiveMessages( arguments.maxMessages, createObject('java', 'java.time.Duration').ofSeconds(arguments.maxWaitTimeSeconds) );
		} else {
			var result = jReceiver.receiveMessages( arguments.maxMessages );
		}
		
		return arrayMap( result.stream().toList(), (i)=> {
				return wirebox.getInstance( 'ReceiverMessage@ServiceBusSDK', { receiver : this,  jMessage : i } );
		} );
	}
	
	/**
	 * Return the message to the queue or topic so it can be processed again later.
	 * This is only available if the receiver is in PEEK_LOCK mode and autocomplete has not been disabled.
	 * 
	 * TODO: AbandonOptions
	 * 
	 * @param message The message to abandon.
	 */
	function abandon( required message ) {
		jReceiver.abandon( message.getJMessage() );
	}

	/**
	 * Complete the message.  This will remove the message from the queue or topic.
	 * This is only available if the receiver is in PEEK_LOCK mode and autocomplete has not been disabled.
	 * 
	 * TODO: CompleteOptions
	 * 
	 * @param message The message to complete.
	 */
	function complete( required message ){
		jReceiver.complete( message.getJMessage() );
	}

	/**
	 * Dead letter the message.  This will move the message to the dead letter queue.
	 * This is only available if the receiver is in PEEK_LOCK mode and autocomplete has not been disabled.
	 * 
	 * TODO: DeadLetterOptions
	 * 
	 * @param message The message to dead letter.
	 */
	function deadLetter( required message ){
		jReceiver.deadLetter( message.getJMessage() );
	}

	/**
	 * Defer the message.  This will move the message to the deferred queue.
	 * This is only available if the receiver is in PEEK_LOCK mode and autocomplete has not been disabled.
	 * 
	 * TODO: DeferOptions
	 * 
	 * @param message The message to defer.
	 */
	function defer( required message ){
		jReceiver.defer( message.getJMessage() );
	}
	
	/**
	 * Internal helper to produce a functional java function that returns a Mono.just() of the data passed in.
	 */
	private function getJJustFunction() {
		return createDynamicProxy(
				new ServiceBusSDK.modules.cbproxies.models.Function( ( data )=>{
					return getJMonoClass().just( data );
					} ),
				['java.util.function.Function']
			)
	}

	/**
	 * Call this when the app shuts down or reinits.
	 * This is very important so that orphaned connections are not left in memory
	 */
	function shutdown() {
		lock timeout="20" type="exclusive" name="Service Bus shutdown - receiver #getID()#" {
			// clean-up tasks here
			if( !isNull( getJreceiver() ) ) {
				getJreceiver().close();
				getSBClient().unregisterreceiver( this );
			}
		}
	}

}
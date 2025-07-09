/**
*********************************************************************************
* Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* Service Bus Sender.  This class is used to send message to a queue or a topic.
* It wraps an underlying connection and is thread safe.  Feel free to re-use it
* for the duration of your application.  It can only send one message at a time,
* so for high concurrency, you can can create multiple senders.
* If you don't the shutdown() method when you're done using it, you'll leave orphaned connections open.
*/
component accessors=true ThreadSafe {

	// DI
	property name="wirebox" inject="wirebox";
	property name="log" inject="logbox:logger:{this}";


	property name="SBClient";
	property name="ID";
	property name="jSender";

	/**
	 * Constructor
	 */
	function init(  Client SBClient,  Struct senderProperties ) {
		setSBClient( arguments.SBClient );
		setID( createUUID() );


		if( senderProperties.queueName.isEmpty() && senderProperties.topicName.isEmpty() ) {
			throw( message='You must specify either a queueName or topicName to build a sender.' );
		}
		var senderBuilder = SBClient.newClientBuilder( senderProperties.fullyQualifiedNamespace )
			.sender();
			
		if( !senderProperties.queueName.isEmpty() ) {
			senderBuilder.queueName( senderProperties.queueName );
		} else if( !senderProperties.topicName.isEmpty() ) {
			senderBuilder.topicName( senderProperties.topicName );
		}
			
		if( senderProperties.async ) {
			setJSender( senderBuilder.buildAsyncClient() );
		} else {
			setJSender( senderBuilder.buildClient() );
		}

		return this;
	}

	/**
	 * Send a message to the Service Bus.
	 * 
	 * Possible messageMeta keys:
	 * - contentType: The content type of the message (e.g., "application/json")
	 * - correlationId: A unique identifier for correlating messages
	 * - messageId: A unique identifier for the message
	 * - partitionKey: The partition key for the message
	 * - replyTo: The reply-to address for the message
	 * - replyToSessionId: The session ID for the reply-to address
	 * - scheduledEnqueueTime: The time to schedule the message for enqueueing (pass an OffsetDateTime instance, a CF date, or a string to parse using OffsetDateTime.parse())
	 * - sessionId: The session ID for the message
	 * - subject: The subject of the message
	 * - timeToLive: The time to live for the message in seconds (pass a number)
	 * - to: The destination address for the message
	 * - properties: A struct of additional application properties to set on the message.  These are arbitrary key-value pairs that will be serialized.
	 * 
	 * @param message The message to send, can be a string or a struct/array
	 * @param messageMeta Optional metadata for the message, such as contentType, correlationId, etc.
	 * @return void
	 */
	Sender function sendMessage( required Any message, Struct messageMeta={} ) {
		getJSender().sendMessage( buildMessage( arguments.message, arguments.messageMeta ) );
		return this;
	}

	/**
	 * Private helper to build a ServiceBusMessage from input and metadata.
	 */
	private any function buildMessage( required any message, struct messageMeta = {} ) {
		if( !isSimpleValue( message ) ) {
			message = serializeJSON( message );			
			messageMeta.properties = messageMeta.properties ?: {};
			// This flag is how we tell if JSON found in the message should be left as a string or serialized as JSON automatically.
			messageMeta.properties[ '_autoJSON' ] = true;
			messageMeta.contentType = messageMeta.contentType ?: 'application/json';
		} else {
			messageMeta.contentType = messageMeta.contentType ?: 'text/plain';
		}

		var jMessage = createObject( 'java', 'com.azure.messaging.servicebus.ServiceBusMessage' ).init( message );

		// Set message metadata
		if( messageMeta.keyExists( 'contentType' ) ) {
			jMessage.setContentType( messageMeta.contentType.toString() );
		}
		if( messageMeta.keyExists( 'correlationId' ) ) {
			jMessage.setCorrelationId( messageMeta.correlationId.toString() );
		}
		if( messageMeta.keyExists( 'messageId' ) ) {
			jMessage.setMessageId( messageMeta.messageId.toString() );
		}
		if( messageMeta.keyExists( 'partitionKey' ) ) {
			jMessage.setPartitionKey( messageMeta.partitionKey.toString() );
		}
		if( messageMeta.keyExists( 'replyTo' ) ) {
			jMessage.setReplyTo( messageMeta.replyTo.toString() );
		}
		if( messageMeta.keyExists( 'replyToSessionId' ) ) {
			jMessage.setReplyToSessionId( messageMeta.replyToSessionId.toString() );
		}
		if( messageMeta.keyExists( 'scheduledEnqueueTime' ) ) {
			// Accepts either a java.time.OffsetDateTime, a date string, or a ColdFusion date object
			var enqueueTime = messageMeta.scheduledEnqueueTime;
			var jOffsetDateTime = "";

			if ( isInstanceOf( enqueueTime, "java.time.OffsetDateTime" ) ) {
				jOffsetDateTime = enqueueTime;
			} else if ( isDate( enqueueTime ) ) {
				// Convert ColdFusion date to OffsetDateTime (UTC)
				var instant = createObject( "java", "java.util.Date" ).init( enqueueTime ).toInstant();
				var zoneOffset = createObject( "java", "java.time.ZoneOffset" ).UTC;
				jOffsetDateTime = createObject( "java", "java.time.OffsetDateTime" ).ofInstant( instant, zoneOffset );
			} else if ( isSimpleValue( enqueueTime ) ) {
				// Try to parse string to OffsetDateTime
				jOffsetDateTime = createObject( "java", "java.time.OffsetDateTime" ).parse( enqueueTime.toString() );
			} else {
				throw( message="Unable to convert scheduledEnqueueTime to OffsetDateTime." );
			}

			jMessage.setScheduledEnqueueTime( jOffsetDateTime );
		}
		if( messageMeta.keyExists( 'sessionId' ) ) {
			jMessage.setSessionId( messageMeta.sessionId.toString() );
		}
		if( messageMeta.keyExists( 'subject' ) ) {
			jMessage.setSubject( messageMeta.subject.toString() );
		}
		if( messageMeta.keyExists( 'timeToLive' ) && isNumeric( messageMeta.timeToLive ) ) {
			jMessage.setTimeToLive(
				createObject('java', 'java.time.Duration').ofSeconds(messageMeta.timeToLive)
			);
		}
		if( messageMeta.keyExists( 'to' ) ) {
			jMessage.setTo( messageMeta.to.toString() );
		}
		if ( messageMeta.keyExists( "properties" ) && isStruct( messageMeta.properties ) ) {
			var appProps = jMessage.getApplicationProperties();
			for ( var key in messageMeta.properties ) {
				appProps.put( key.toString(), messageMeta.properties[ key ] );
			}
		}
		return jMessage;
	}

	// TODO: send message batches https://javadoc.io/static/com.azure/azure-messaging-servicebus/7.17.12/com/azure/messaging/servicebus/ServiceBusSenderClient.html#sendMessages(com.azure.messaging.servicebus.ServiceBusMessageBatch)
	// TODO: schedule message https://javadoc.io/static/com.azure/azure-messaging-servicebus/7.17.12/com/azure/messaging/servicebus/ServiceBusSenderClient.html#scheduleMessage(com.azure.messaging.servicebus.ServiceBusMessage,java.time.OffsetDateTime)
	// TODO: cancel scheduled message https://javadoc.io/static/com.azure/azure-messaging-servicebus/7.17.12/com/azure/messaging/servicebus/ServiceBusSenderClient.html#cancelScheduledMessage(long)

	/**
	 * Call this when the app shuts down or reinits.
	 * This is very important so that orphaned connections are not left in memory
	 */
	function shutdown() {
		lock timeout="20" type="exclusive" name="Service Bus shutdown - sender #getID()#" {
			// clean-up tasks here
			if( !isNull( getJSender() ) ) {
				getJSender().close();
				getSBClient().unregisterSender( this );
			}
		}
	}

}
/**
* This is a transient that represents a single message
*/
component accessors='true'  {

	property name='jMessage';
		
	property name='body';
	property name='properties' type='struct';
	property name='contentType';
	property name='correlationId';
	property name='deadLetterErrorDescription';
	property name='deadLetterReason';
	property name='deadLetterSource';
	property name='deliveryCount';
	property name='enqueuedSequenceNumber';
	property name='enqueuedTime';
	property name='expiresAt';
	property name='lockedUntil';
	property name='lockToken';
	property name='messageId';
	property name='partitionKey';
	property name='replyTo';
	property name='replyToSessionId';
	property name='scheduledEnqueueTime';
	property name='sequenceNumber';
	property name='sessionId';
	property name='state';
	property name='subject';
	property name='timeToLive';
	property name='to';

	/**
	* Constructor
	*/
	function init( required jMessage ) {
		setJMessage( jMessage );
		setBody( toString( jMessage.getBody().toString() ) );

		setProperties( jMessage.getApplicationProperties() );
		
		// Force this to be a native CFML Struct instead of Map<String,Object>
		var emptyStruct = {};
		setProperties( emptyStruct.append( getProperties().map( (k,v)=>v.toString() ) ) );
		
		// Populate message metadata properties
		setContentType( jMessage.getContentType() );
		setCorrelationId( jMessage.getCorrelationId() );
		setDeadLetterErrorDescription( jMessage.getDeadLetterErrorDescription() );
		setDeadLetterReason( jMessage.getDeadLetterReason() );
		setDeadLetterSource( jMessage.getDeadLetterSource() );
		setDeliveryCount( jMessage.getDeliveryCount() );
		setEnqueuedSequenceNumber( jMessage.getEnqueuedSequenceNumber() );
		setEnqueuedTime( jMessage.getEnqueuedTime() );
		setExpiresAt( jMessage.getExpiresAt() );
		setLockedUntil( jMessage.getLockedUntil() );
		setLockToken( jMessage.getLockToken() );
		setMessageId( jMessage.getMessageId() );
		setPartitionKey( jMessage.getPartitionKey() );
		setReplyTo( jMessage.getReplyTo() );
		setReplyToSessionId( jMessage.getReplyToSessionId() );
		setScheduledEnqueueTime( jMessage.getScheduledEnqueueTime() );
		setSequenceNumber( jMessage.getSequenceNumber() );
		setSessionId( jMessage.getSessionId() );
		setState( jMessage.getState() );
		setSubject( jMessage.getSubject() );
		setTimeToLive( jMessage.getTimeToLive() );
		setTo( jMessage.getTo() );
		
		// If we got a complex object in, send it out the same way
		if( getProperty( '_autoJSON', false ) ) {
			setBody( deserializeJSON( getBody() ) );
		}
		
		return this;
	}
	
	/**
	 * Return this message to the queue or topic so it can be processed again later.
	 * This is only available if this message came from a processor or receiver which is
	 * in PEEK_LOCK mode and autocomplete has not been disabled.
	 * 
	 * TODO: AbandonOptions
	 * 
	 */
	function abandon() {
		throw( "message has no assocated receiver context and cannot be abandoned." );
	}

	/**
	 * Complete the message.  This will remove the message from the queue or topic.
	 * This is only available if this message came from a processor or receiver which is
	 * in PEEK_LOCK mode and autocomplete has not been disabled.
	 * 
	 * TODO: CompleteOptions
	 * 
	 */
	function complete(){
		throw( "message has no assocated receiver context and cannot be completed." );
	}

	/**
	 * Dead letter the message.  This will move the message to the dead letter queue.
	 * This is only available if this message came from a processor or receiver which is
	 * in PEEK_LOCK mode and autocomplete has not been disabled.
	 * 
	 * TODO: DeadLetterOptions
	 * 
	 */
	function deadLetter(){
		throw( "message has no assocated receiver context and cannot be dead lettered." );
	}

	/**
	 * Defer the message.  This will move the message to the deferred queue.
	 * This is only available if this message came from a processor or receiver which is
	 * in PEEK_LOCK mode and autocomplete has not been disabled.
	 * 
	 * TODO: DeferOptions
	 * 
	 */
	function defer(){
		throw( "message has no assocated receiver context and cannot be deferred." );
	}

	
	/**
	* @name Name of header	
	* @defaultValue Default value to use if it doesn't exist or is null
	* 
	* Get a specific headerfrom the message.
	*/
	function getProperty( required string name, any defaultValue ){
		var headers = getProperties();
		if( !headers.keyExists( name ) ) {
			if( isNull( defaultvalue ) ) {
				return;
			} else {
				return defaultValue;
			}
		}
		return headers[ name ];
	}
	
	
}
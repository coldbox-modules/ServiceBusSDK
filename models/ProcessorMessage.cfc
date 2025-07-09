/**
* This is a transient that represents a single message
*/
component accessors='true' extends='Message' {

	property name='jMessageContext';

	/**
	 * Constructor
	 */
	function init( required jMessageContext ) {
		setJMessageContext( arguments.jMessageContext );
		super.init( arguments.jMessageContext.getMessage() );
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
		jMessageContext.abandon();
		return this;
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
		jMessageContext.complete();
		return this;
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
		jMessageContext.deadLetter();
		return this;
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
		jMessageContext.defer();
		return this;
	}
	
}
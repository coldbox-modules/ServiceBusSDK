/**
* This is a transient that represents a single message
*/
component accessors='true' extends='Message' {

	property name='receiver';
	
	/**
	 * Constructor
	 */
	function init( required receiver, required jMessage ) {
		setReceiver( receiver );
		super.init( jMessage );
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
		getReceiver().abandon( this );
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
		getReceiver().complete( this );
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
		getReceiver().deadLetter( this );
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
		getReceiver().defer( this );
		return this;
	}
	
}
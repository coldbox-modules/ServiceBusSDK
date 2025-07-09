/**
* This is a transient that represents a single async message
* The first time a method is called on this object, it will block until the Mono is resolved.
*/
component accessors='true' {

	property name="wirebox" inject="wirebox";

	property name='receiver';
	property name='message';
	property name='mono';
	
	/**
	 * Constructor
	 */
	function init( required receiver, required mono ) {
		setReceiver( arguments.receiver );
		setMono( arguments.mono );
		return this;
	}
	
	/**
	 * Funnel all methods to the message object.
	 * This will block the Mono the first time a method is called.
	 */
	function onMissingMethod( required missingMethodName , required missingMethodArguments  ) {
		if( isNull( getMessage() ) ) {			
			setMessage( 
				wirebox.getInstance( 'ReceiverMessage@ServiceBusSDK', { receiver : getReceiver(),  jMessage : getMono().block() } )
			);
		}
		return invoke( getMessage(), missingMethodName , missingMethodArguments  );
	}
}
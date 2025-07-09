/**
*********************************************************************************
* Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* Service Bus processor.  This class is used to process messages from a queue or a topic.
* It wraps an underlying connection and is thread safe.  Feel free to re-use it
* for the duration of your application.  To process messages concurrently, set your maxConcurrentCalls property
* to the number threads you want to process concurrently.
*
* If you don't the shutdown() method when you're done using it, you'll leave orphaned connections open.
*/
component accessors=true ThreadSafe {

	// DI
	property name="wirebox" inject="wirebox";
	property name="log" inject="logbox:logger:{this}";


	property name="SBClient";
	property name="ID";
	property name="jProcessor";

	/**
	 * Constructor
	 */
	function init(  Client SBClient,  Struct processorProperties ) {
		setSBClient( arguments.SBClient );
		setID( createUUID() );


		if( processorProperties.queueName.isEmpty() && processorProperties.topicName.isEmpty() ) {
			throw( message='You must specify either a queueName or topicName to build a processor.' );
		}
		var processorBuilder = SBClient.newClientBuilder( processorProperties.fullyQualifiedNamespace )
			.processor();
			
		if( !processorProperties.queueName.isEmpty() ) {
			processorBuilder.queueName( processorProperties.queueName );
		} else if( !processorProperties.topicName.isEmpty() ) {
			processorBuilder.topicName( processorProperties.topicName );
		}

		if( !isNull( processorProperties.prefetchCount ) && isNumeric( processorProperties.prefetchCount ) ) {
			processorBuilder.prefetchCount( processorProperties.prefetchCount );
		}

		processorBuilder.receiveMode( createObject( 'java', 'com.azure.messaging.servicebus.models.ServiceBusReceiveMode' ).valueOf( processorProperties.receiveMode.ucase() ) );

		// if we are in RECEIVE_AND_DELETE mode, we cannot auto complete messages
		if( !processorProperties.autoComplete || processorProperties.receiveMode == 'RECEIVE_AND_DELETE' ) {
			processorBuilder.disableAutoComplete();
		}

		if( !isNull( processorProperties.maxConcurrentCalls ) && isNumeric( processorProperties.maxConcurrentCalls ) ) {
			processorBuilder.maxConcurrentCalls( processorProperties.maxConcurrentCalls );
		}

		if( !isNull( processorProperties.onMessage ) && isCustomFunction( processorProperties.onMessage ) ) {
			processorBuilder.processMessage( 
				createDynamicProxy(
					new ServiceBusSDK.modules.cbproxies.models.Consumer( ( messageContext )=>{
						var message = wirebox.getInstance( 'ProcessorMessage@ServiceBusSDK', { jMessageContext : messageContext } );
						processorProperties.onMessage( message );
					} ),
					['java.util.function.Consumer']
				)
			);
		}

		if( isNull( processorProperties.onError ) || !isCustomFunction( processorProperties.onError ) ) {
			processorProperties.onError = function( exception, entityPath, errorSource, fullyQualifiedNamespace ) {
				log.error( 'Service Bus processor error: #exception.message#' );
				exception.printStackTrace();
			};
		}

		processorBuilder.processError( 
			createDynamicProxy(
				new ServiceBusSDK.modules.cbproxies.models.Consumer( ( errorContext )=>{
						processorProperties.onError( 
							errorContext.getException(), 
							errorContext.getEntityPath(),
							errorContext.getErrorSource(),
							errorContext.getFullyQualifiedNamespace()
						);
					} ),
				['java.util.function.Consumer']
			)
		);

		setJProcessor( processorBuilder.buildProcessorClient() );

		if( processorProperties.autoStart ) {
			start();
		}

		return this;
	}

	/**
	 * Returns true if the processor is running.
	 */
	function isRunning() {
		return getJProcessor().isRunning();
	}

	/**
	 * Starts the processor.
	 */
	function start() {
		log.debug( 'Starting Service Bus processor with ID: #getID()#.' );
		getJProcessor().start();
		return this;
	}

	/**
	 * Stops the processor.
	 */
	function stop() {
		log.debug( 'Stopping Service Bus processor with ID: #getID()#.' );
		getJProcessor().stop();
		return this;
	}

	/**
	 * Call this when the app shuts down or reinits.
	 * This is very important so that orphaned connections are not left in memory
	 */
	function shutdown() {
		lock timeout="20" type="exclusive" name="Service Bus shutdown - processor #getID()#" {
			// clean-up tasks here
			if( !isNull( getJprocessor() ) ) {
				getJprocessor().close();
				getSBClient().unregisterprocessor( this );
			}
		}
	}

}
/**
*********************************************************************************
* Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* Service Bus Client.  This is a singleton that represents your entrypoint into all service bus operations.
* Only create me once and ask me to build senders, receivers, and processors for you to use.
* ALWAYS make sure you call the shutdown() method when you're done using or you'll leave orphaned connections open.
*/
component accessors=true singleton ThreadSafe {

	// DI
	property name="settings" inject="box:moduleSettings:ServiceBusSDK";
	property name="wirebox" inject="wirebox";
	property name="moduleConfig" inject="box:moduleConfig:ServiceBusSDK";
	property name="interceptorService" inject="box:InterceptorService";
	property name="log" inject="logbox:logger:{this}";

	property name="senderRegistry";
	property name="processorRegistry";
	property name="receiverRegistry";


	/**
	 * Constructor
	 */
	function init(){
		return this;
	}

	function onDIComplete(){
		log.debug( 'Service Bus client intialized.' );
		setSenderRegistry( {} );
		setProcessorRegistry( {} );
		setReceiverRegistry( {} );
		interceptorService.registerInterceptor(
			interceptor 	= this,
			interceptorObject 	= this,
			interceptorName 	= "ServiceBusSDK-client"
		);
	}

	/**
	 * https://javadoc.io/doc/com.azure/azure-messaging-servicebus/7.17.12/com/azure/messaging/servicebus/ServiceBusClientBuilder.html
	 * Creates a new ServiceBusClientBuilder instance.
	 */
	function newClientBuilder( required string fullyQualifiedNamespace ) {
		var clientBuilder = createObject( 'java', 'com.azure.messaging.servicebus.ServiceBusClientBuilder' ).init();

		if( !isNull( arguments.fullyQualifiedNamespace ) && !arguments.fullyQualifiedNamespace.isEmpty() ) {
			clientBuilder.fullyQualifiedNamespace( arguments.fullyQualifiedNamespace );
		
		}
		var credOptions = settings.credentials;

		if( credOptions.type == 'connectionString' ) {
			clientBuilder.connectionString( credOptions.connectionString );
		} else if( credOptions.type == 'default' ) {
			var credBuilder = createObject( 'java', 'com.azure.identity.DefaultAzureCredentialBuilder' ).init();
			
			doAuthorityHost( credOptions, credBuilder );
			doTenantId( credOptions, credBuilder );
			doMaxRetry( credOptions, credBuilder );
			doTokenRefreshOffset( credOptions, credBuilder );

			clientBuilder.credential( credBuilder.build() );
		} else if( credOptions.type == 'ClientSecret' ) {
			var credBuilder = createObject( 'java', 'com.azure.identity.ClientSecretCredentialBuilder' ).init();

			doAuthorityHost( credOptions, credBuilder );
			doTenantId( credOptions, credBuilder );
			doMaxRetry( credOptions, credBuilder );
			doTokenRefreshOffset( credOptions, credBuilder );
			doClientSecret( credOptions, credBuilder );
			doEnablePersistentCache( credOptions, credBuilder );
			doClientId( credOptions, credBuilder );

			clientBuilder.credential( credBuilder.build() );
		} else if( credOptions.type == 'ClientCertificate' ) {
			var credBuilder = createObject( 'java', 'com.azure.identity.ClientCertificateCredentialBuilder' ).init();

			doAuthorityHost( credOptions, credBuilder );
			doClientId( credOptions, credBuilder );
			doTenantId( credOptions, credBuilder );
			doMaxRetry( credOptions, credBuilder );
			doTokenRefreshOffset( credOptions, credBuilder );
			doEnablePersistentCache( credOptions, credBuilder );
			doCertificatePath( credOptions, credBuilder );

			clientBuilder.credential( credBuilder.build() );
		}

		// TODO: implement these more in-depth options
		// .clientOptions()
		// .configuration()
		// .retryOptions()
		// .enableCrossEntityTransactions()
		// .proxyOptions()
		// .retryOptions()
		// .transportType()



		return clientBuilder;
	}

	private function doTokenRefreshOffset( required struct credOptions, required builder ) {
		if( !isNull( credOptions.tokenRefreshOffsetSeconds ) && isNumeric( credOptions.tokenRefreshOffsetSeconds ) && credOptions.tokenRefreshOffsetSeconds > 0 ) {
			builder.tokenRefreshOffset( createObject( "java", "java.time.Duration" ).ofSeconds( credOptions.tokenRefreshOffsetSeconds ) );
		}
		return builder;
	}

	private function doMaxRetry( required struct credOptions, required builder ) {
		if( !isNull( credOptions.maxRetry ) && isNumeric( credOptions.maxRetry ) && credOptions.maxRetry > 0 ) {
			builder.maxRetry( credOptions.maxRetry );
		}
		return builder;
	}

	private function doTenantId( required struct credOptions, required builder ) {
		if( !isNull( credOptions.tenantId ) && !credOptions.tenantId.isEmpty() ) {
			builder.tenantId( credOptions.tenantId );
		}
		return builder;
	}

	private function doAuthorityHost( required struct credOptions, required builder ) {
		if( !isNull( credOptions.authorityHost ) && !credOptions.authorityHost.isEmpty() ) {
			builder.authorityHost( credOptions.authorityHost );
		}
		return builder;
	}

	private function doClientSecret( required struct credOptions, required builder ) {
		if( !isNull( credOptions.clientSecret ) && !credOptions.clientSecret.isEmpty() ) {
			builder.clientSecret( credOptions.clientSecret );
		}
		return builder;
	}

	private function doEnablePersistentCache( required struct credOptions, required builder ) {
		if( !isNull( credOptions.enablePersistentCache ) && isBoolean( credOptions.enablePersistentCache ) ) {
			builder.enablePersistentCache( credOptions.enablePersistentCache );
		}
		return builder;
	}

	private function doClientId( required struct credOptions, required builder ) {
		if( !isNull( credOptions.clientId ) && !credOptions.clientId.isEmpty() ) {
			builder.clientId( credOptions.clientId );
		}
		return builder;
	}

	private function doCertificatePath( required struct credOptions, required builder ) {
		if( !isNull( credOptions.pemCertificatePath ) && !credOptions.pemCertificatePath.isEmpty() ) {
			builder.pemCertificate( credOptions.pemCertificatePath );
		} else if( !isNull( credOptions.pfxCertificatePath ) && !credOptions.pfxCertificatePath.isEmpty() ) {
			builder.pfxCertificate( credOptions.pfxCertificatePath, credOptions.certificatePassword ?: '' );
		}
		return builder;
	}

	/**
	 * https://javadoc.io/doc/com.azure/azure-messaging-servicebus/7.17.12/com/azure/messaging/servicebus/ServiceBusClientBuilder.ServiceBusSenderClientBuilder.html
	 * Creates a new ServiceBusSenderClientBuilder instance.
	 */
	function buildSender( 
		String queueName='',
		String topicName='',
		Boolean async=false,
		String fullyQualifiedNamespace=settings.fullyQualifiedNamespace
	) {
		return registerSender(
			wirebox.getInstance( 'Sender@ServiceBusSDK', { SBClient : this, senderProperties : arguments } )
		);
	}

	/**
	 * https://javadoc.io/doc/com.azure/azure-messaging-servicebus/7.17.12/com/azure/messaging/servicebus/ServiceBusClientBuilder.ServiceBusProcessorClientBuilder.html
	 * Creates a new ServiceBusProcessorClientBuilder
	 */
	// TODO: sub queue, subscription name, maxAutoLockRenewDuration(Duration maxAutoLockRenewDuration)
	function buildProcessor( 
		String queueName='',
		String topicName='',
		Boolean autoComplete=true,
		Numeric prefetchCount,
		String receiveMode='RECEIVE_AND_DELETE',
		Numeric maxConcurrentCalls,
		Function onMessage,
		Function onError,
		boolean autoStart=false,
		String fullyQualifiedNamespace=settings.fullyQualifiedNamespace
	) {
		return registerProcessor(
			wirebox.getInstance( 'Processor@ServiceBusSDK', { SBClient : this, processorProperties : arguments } )
		);
	}

	/**
	 * https://javadoc.io/static/com.azure/azure-messaging-servicebus/7.17.12/com/azure/messaging/servicebus/ServiceBusClientBuilder.ServiceBusReceiverClientBuilder.html
	 * Creates a new ServiceBusReceiverClientBuilder
	 */
	// TODO: sub queue, subscription name, maxAutoLockRenewDuration(Duration maxAutoLockRenewDuration)
	function buildReceiver( 
		String queueName='',
		String topicName='',
		Boolean autoComplete=true,
		Numeric prefetchCount,
		String receiveMode='RECEIVE_AND_DELETE',
		Boolean async=false,
		String fullyQualifiedNamespace=settings.fullyQualifiedNamespace
	) {
		return registerReceiver(
			wirebox.getInstance( 'Receiver@ServiceBusSDK', { SBClient : this, receiverProperties : arguments } )
		);
	}

	/**
	 * Creates an auto-closing channel for multiple operations.  Do not store the channel reference passed to the callback
	 * as it will be closed as soon as the UDF is finished.  Any value returned from the UDF will be returned from the
	 * batch method.
	 * This allows you to not need to worry about closing the channel.  Also, if you have a large number of operations to
	 * perform on the channel, you can perform them all inside your UDF.
	 */
	function batch( required any udf ) {
		try {
			var channel = createChannel();
			return udf( channel );
		} finally {
			if( !isNull( channel ) ) {
				channel.close();
			}
		}
	}

	/**
	 * Register a sender with the client.  This is used to track senders
	 * so that we can close them all when the client is shutdown.
	 * @param Sender sender The sender to register
	 * @return Sender The sender that was registered
	 */
	Sender function registerSender( required Sender sender ) {
		getSenderRegistry()[ sender.getID() ] = sender;
		return sender;
	}

	/**
	 * Stop tracking this sender.  We assume it was shutdown separately.
	 * @param Sender sender The sender to unregister
	 * @return void
	 */
	function unregisterSender( required Sender sender ) {
		getSenderRegistry().delete( sender.getID() );
	}

	/**
	 * Register a processor with the client.  This is used to track processors
	 * so that we can close them all when the client is shutdown.
	 * @param Processor processor The processor to register
	 * @return Processor The processor that was registered
	 */
	function registerProcessor( required Processor processor ) {
		getProcessorRegistry()[ processor.getID() ] = processor;
		return processor;
	}
	
	/**
	 * Stop tracking this processor.  We assume it was shutdown separately.
	 * @param Processor processor The processor to unregister
	 * @return void
	 */
	function unregisterProcessor( required Processor processor ) {
		getProcessorRegistry().delete( processor.getID() );
	}

	/**
	 * Register a receiver with the client.  This is used to track receivers
	 * so that we can close them all when the client is shutdown.
	 * @param Receiver receiver The receiver to register
	 * @return Receiver The receiver that was registered
	 */
	function registerReceiver( required Receiver receiver ) {
		getReceiverRegistry()[ receiver.getID() ] = receiver;
		return receiver;
	}

	/**
	 * Stop tracking this receiver.  We assume it was shutdown separately.
	 * @param Receiver receiver The receiver to unregister
	 * @return void
	 */
	function unregisterReceiver( required Receiver receiver ) {
		getReceiverRegistry().delete( receiver.getID() );
	}

	/**
	 * Listen to the ColdBox app reinitting or shutting down
	 */
	function preReinit() {
		log.debug( 'Framework shutdown detected.' );
		shutdown();
	}

	/**
	 * Listen to the CommandBox CLI shutting down
	 */
	function onCLIExit() {
		log.debug( 'CLI shutdown detected.' );
		shutdown();
	}

	/**
	 * Call this when the app shuts down or reinits.
	 * This is very important so that orphaned connections are not left in memory
	 */
	function shutdown() {
		lock timeout="20" type="exclusive" name="Service Bus shutdown" {
			log.debug( 'Shutting down Service Bus client' );
			// clean-up tasks here

			// Close all senders
			getSenderRegistry().each( function( key, sender ){
				try {
					// The sender will unregister itself from us when it shuts down
					sender.shutdown();
				} catch( any e ) {
					log.error( 'Error closing sender [#key#]: #e.message#' );
				}
			} );
			// the sender registry should be empty now

			getProcessorRegistry().each( function( key, processor ){
				try {
					// The processor will unregister itself from us when it shuts down
					processor.shutdown();
				} catch( any e ) {
					log.error( 'Error closing processor [#key#]: #e.message#' );
				}
			} );
			// the processor registry should be empty now

			getReceiverRegistry().each( function( key, receiver ){
				try {
					// The receiver will unregister itself from us when it shuts down
					receiver.shutdown();
				} catch( any e ) {
					log.error( 'Error closing receiver [#key#]: #e.message#' );
				}
			} );
			// the receiver registry should be empty now

			interceptorService.unregister( "ServiceBusSDK-client" );
		}
	}

}
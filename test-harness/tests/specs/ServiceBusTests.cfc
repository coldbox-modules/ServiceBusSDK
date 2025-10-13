component extends='coldbox.system.testing.BaseTestCase' appMapping='/root'{

/*********************************** LIFE CYCLE Methods ***********************************/

	this.unloadColdBox = true;

	// executes before all suites+specs in the run() method
	function beforeAll(){
		super.beforeAll();		
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
		getSBClient().shutdown();
		super.afterAll();
	}

/*********************************** BDD SUITES ***********************************/

	function run(){
		
		describe( 'ServiceBusSDK Module', function(){

			/* logManager = createObject("java", "org.apache.logging.log4j.LogManager");
			levelClass = createObject("java", "org.apache.logging.log4j.Level");
			context = logManager.getContext(false);
			config = context.getConfiguration();

			// Silence com.azure
			azureLoggerConfig = config.getLoggerConfig("com.azure");
			azureLoggerConfig.setLevel(levelClass.OFF);

			// Silence reactor.netty
			reactorLoggerConfig = config.getLoggerConfig("reactor.netty");
			reactorLoggerConfig.setLevel(levelClass.OFF);

			// Apply the changes
			context.updateLoggers(); */

			beforeEach(function( currentSpec ){
				setup();
			});

			describe( 'Client management', function(){
					
				it( 'should register library', function(){
					var sbClient = getSBClient();
					expect(	sbClient ).toBeComponent();
				});

				it( 'can build sender', function(){
					var sbClient = getSBClient();
					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					expect(	sender ).toBeComponent();
				});

				it( 'can send message', function(){
					var sbClient = getSBClient();
					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					sender.sendMessage( { orderId=12345, customerName='John Doe' } );
				});

				it( 'can build processor', function(){
					var sbClient = getSBClient();
					var processor = sbClient.buildProcessor(
						queueName='new-orders',
						onMessage=function( message ){
							log.info( 'Received message: ' & serializeJSON( message ) );
						}
					);
					expect(	processor ).toBeComponent();
				});

				it( 'can start processor', function(){
					var sbClient = getSBClient();
					var processor = sbClient.buildProcessor(
						queueName='new-orders',
						onMessage=function( message ){
							createObject('java', 'java.lang.System').out.println( 'Received message: ' & serializeJSON( message.getBody() ) );
						},
						maxConcurrentCalls=1
					);
					createObject('java', 'java.lang.System').out.println( 'Starting processor threads...' );
					processor.start();
					sleep( 1000 );
					processor.stop();
				});

				it( 'can build receiver', function(){
					var sbClient = getSBClient();
					var receiver = sbClient.buildReceiver(
						queueName='new-orders'
					);
					expect(	receiver ).toBeComponent();
				});

				it( 'can peek sync', function(){
					var sbClient = getSBClient();

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					sender.sendMessage( { orderId=12345, customerName='John Doe' } );
					sender.sendMessage( { orderId=67890, customerName='Jane Smith' } );
					sender.sendMessage( { orderId=54321, customerName='Alice Johnson' } );
					sender.sendMessage( { orderId=98765, customerName='Bob Brown' } );
					sender.sendMessage( { orderId=11223, customerName='Charlie White' } );

					var receiver = sbClient.buildReceiver(
						queueName='new-orders'
					);
					
					var message = receiver.peekMessage();
					message = receiver.peekMessage( 2 );
					//writedump( message.getBody() );
				});

				it( 'can peek multiple sync', function(){
					var sbClient = getSBClient();

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					sender.sendMessage( { orderId=12345, customerName='John Doe' } );
					sender.sendMessage( { orderId=67890, customerName='Jane Smith' } );
					sender.sendMessage( { orderId=54321, customerName='Alice Johnson' } );
					sender.sendMessage( { orderId=98765, customerName='Bob Brown' } );
					sender.sendMessage( { orderId=11223, customerName='Charlie White' } );

					var receiver = sbClient.buildReceiver(
						queueName='new-orders'
					);
					
					var messages = receiver.peekMessages( 5 );
					expect( messages ).toBeArray();
					expect( messages.len() ).toBeGT( 0 );

					messages = receiver.peekMessages( 5, 2 );
					expect( messages ).toBeArray();
					expect( messages.len() ).toBeGT( 0 );
				});

				it( 'can peek async', function(){
					var sbClient = getSBClient();

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					sender.sendMessage( { orderId=12345, customerName='John Doe' } );
					sender.sendMessage( { orderId=67890, customerName='Jane Smith' } );
					sender.sendMessage( { orderId=54321, customerName='Alice Johnson' } );
					sender.sendMessage( { orderId=98765, customerName='Bob Brown' } );
					sender.sendMessage( { orderId=11223, customerName='Charlie White' } );

					var receiver = sbClient.buildReceiver(
						queueName='new-orders',
						async=true
					);
					
					var message = receiver.peekMessage();
					message = receiver.peekMessage( 2 );
					//writedump( message.getBody() );
				});

				it( 'can peek multiple async', function(){
					var sbClient = getSBClient();

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					sender.sendMessage( { orderId=12345, customerName='John Doe' } );
					sender.sendMessage( { orderId=67890, customerName='Jane Smith' } );
					sender.sendMessage( { orderId=54321, customerName='Alice Johnson' } );
					sender.sendMessage( { orderId=98765, customerName='Bob Brown' } );
					sender.sendMessage( { orderId=11223, customerName='Charlie White' } );

					var receiver = sbClient.buildReceiver(
						queueName='new-orders',
						async=true
					);
					
					var messages = receiver.peekMessages( 5 );
					expect( messages ).toBeArray();
					expect( messages.len() ).toBeGT( 0 );
					messages.map( (m)=>m.getBody() );

					messages = receiver.peekMessages( 5, 2 );
					expect( messages ).toBeArray();
					expect( messages.len() ).toBeGT( 0 );
				});

				it( 'can receive sync', function(){
					var sbClient = getSBClient();

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					sender.sendMessage( { orderId=12345, customerName='John Doe' } );
					sender.sendMessage( { orderId=67890, customerName='Jane Smith' } );
					sender.sendMessage( { orderId=54321, customerName='Alice Johnson' } );
					sender.sendMessage( { orderId=98765, customerName='Bob Brown' } );
					sender.sendMessage( { orderId=11223, customerName='Charlie White' } );

					var receiver = sbClient.buildReceiver(
						queueName='new-orders'
					);

					var message = receiver.receiveMessage( 2 );
					//writedump( message.getBody() );
				});

				it( 'can receive multiple sync', function(){
					var sbClient = getSBClient();

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					sender.sendMessage( { orderId=12345, customerName='John Doe' } );
					sender.sendMessage( { orderId=67890, customerName='Jane Smith' } );
					sender.sendMessage( { orderId=54321, customerName='Alice Johnson' } );
					sender.sendMessage( { orderId=98765, customerName='Bob Brown' } );
					sender.sendMessage( { orderId=11223, customerName='Charlie White' } );

					var receiver = sbClient.buildReceiver(
						queueName='new-orders'
					);
					
					var messages = receiver.receiveMessages( 5, 2 );
					expect( messages ).toBeArray();
					expect( messages.len() ).toBeGT( 0 );
					//writedump( messages.map( (m)=>m.getBody() ) );
				});

				// receiving one or more messages async is not supported.  Just use a processor.  No need to re-invent that wheel.
				

				it( 'can receive and abandon', function(){
					var sbClient = getSBClient();

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					sender.sendMessage( { orderId=12345, customerName='John Doe' } );

					var receiver = sbClient.buildReceiver(
						queueName='new-orders',
						receiveMode='PEEK_LOCK'
					);

					var message = receiver.receiveMessage( 2 );
					//writedump( message.getBody() );
					message.abandon();
				});

				it( 'can receive and complete', function(){
					var sbClient = getSBClient();

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					sender.sendMessage( { orderId=12345, customerName='John Doe' } );

					var receiver = sbClient.buildReceiver(
						queueName='new-orders',
						receiveMode='PEEK_LOCK'
					);

					var message = receiver.receiveMessage( 2 );
					//writedump( message );
					message.complete();
				});

				it( 'can handle deferred messages', function(){
					var sbClient = getSBClient();

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					sender.sendMessage( { orderId=12345, customerName='John Doe' } );

					var receiver = sbClient.buildReceiver(
						queueName='new-orders',
						receiveMode='PEEK_LOCK'
					);

					var message = receiver.receiveMessage( 2 );
					var seqNum = message.defer();

					var message = receiver.receiveDeferredMessage( seqNum );
					message.complete();
				});

				it( 'can scheduled message time via meta', function(){
					var sbClient = getSBClient();

					var receiver = sbClient.buildReceiver(
						queueName='new-orders',
						receiveMode='RECEIVE_AND_DELETE'
					);
					// purge the queue
					var message = receiver.receiveMessage( 1 );
					while( !isNull( message ) ) {
						message = receiver.receiveMessage( 1 );
					}

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					var secondsToWait = 3;
					var start = getTickCount();
					sender.sendMessage( 
						{ orderId=12345, customerName='scheduled John Doe' }, 
						{ scheduledEnqueueTime=createObject("java", "java.time.OffsetDateTime").now(createObject("java", "java.time.ZoneOffset").UTC).plusSeconds(secondsToWait) } 
					);

					var message = receiver.receiveMessage( 5 );
					var secondsTaken = (getTickCount()-start)/1000;
					expect( secondsTaken ).toBeGTE( secondsToWait );
				});

				it( 'can scheduled message delay seconds via meta', function(){
					var sbClient = getSBClient();

					var receiver = sbClient.buildReceiver(
						queueName='new-orders',
						receiveMode='RECEIVE_AND_DELETE'
					);
					// purge the queue
					var message = receiver.receiveMessage( 1 );
					while( !isNull( message ) ) {
						message = receiver.receiveMessage( 1 );
					}

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					var secondsToWait = 3;
					var start = getTickCount();
					sender.sendMessage( 
						{ orderId=12345, customerName='scheduled John Doe' }, 
						{ scheduledDelaySeconds=secondsToWait } 
					);

					var message = receiver.receiveMessage( 5 );
					var secondsTaken = (getTickCount()-start)/1000;
					expect( secondsTaken ).toBeGTE( secondsToWait );
				});

				it( 'can scheduled message time via args', function(){
					var sbClient = getSBClient();

					var receiver = sbClient.buildReceiver(
						queueName='new-orders',
						receiveMode='RECEIVE_AND_DELETE'
					);
					// purge the queue
					var message = receiver.receiveMessage( 1 );
					while( !isNull( message ) ) {
						message = receiver.receiveMessage( 1 );
					}

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					var secondsToWait = 3;
					var start = getTickCount();
					sender.sendMessage( 
						message={ orderId=12345, customerName='scheduled John Doe' },
						scheduledEnqueueTime=createObject("java", "java.time.OffsetDateTime").now(createObject("java", "java.time.ZoneOffset").UTC).plusSeconds(secondsToWait)
					);

					var message = receiver.receiveMessage( 5 );
					var secondsTaken = (getTickCount()-start)/1000;
					expect( secondsTaken ).toBeGTE( secondsToWait );
				});

				it( 'can scheduled message delay seconds via args', function(){
					var sbClient = getSBClient();

					var receiver = sbClient.buildReceiver(
						queueName='new-orders',
						receiveMode='RECEIVE_AND_DELETE'
					);
					// purge the queue
					var message = receiver.receiveMessage( 1 );
					while( !isNull( message ) ) {
						message = receiver.receiveMessage( 1 );
					}

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					var secondsToWait = 3;
					var start = getTickCount();
					sender.sendMessage( 
						message={ orderId=12345, customerName='scheduled John Doe' },
						scheduledDelaySeconds=secondsToWait
					);

					var message = receiver.receiveMessage( 5 );
					var secondsTaken = (getTickCount()-start)/1000;
					expect( secondsTaken ).toBeGTE( secondsToWait );
				});

				it( 'can deadLetter a message', function(){
					var sbClient = getSBClient();

					var sender = sbClient.buildSender(
						queueName='new-orders'
					);
					sender.sendMessage( { orderId=12345, customerName='John Doe' } );

					var receiver = sbClient.buildReceiver(
						queueName='new-orders',
						receiveMode='PEEK_LOCK'
					);

					var message = receiver.receiveMessage( 2 );
					var seqNum = message.deadLetter( deadLetterErrorDescription="dead letter desc", deadLetterReason="dead letter reason" );

				});

			});
	
		});
				
	}

	private function getSBClient( name='Client@ServiceBusSDK' ){
		return getWireBox().getInstance( name );
	}

}
package com.tavernari.asworker
{
	import com.tavernari.asworker.notification.NotificationCenter;
	
	import flash.concurrent.Mutex;
	import flash.display.Stage;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.utils.ByteArray;

	internal class ASUIWorker
	{
		public static const MESSAGE_CHANNEL_UI:String = "asw_mcui";
		
		private var mainMessageChannel:MessageChannel;
		private var backMessageChannel:MessageChannel;
		private var worker:Worker;
		
		private var backSpeakerBA:ByteArray;
		private var uiSpeakerBA:ByteArray;
		private var uiMutex:Mutex;
		private var backMutex:Mutex;
		
		private var workerToNotification:WorkerToNotification;
		
		public function ASUIWorker(stage:Stage)
		{
			if(Worker.isSupported)
			{
				if(Worker.current.isPrimordial)
				{
					worker = WorkerDomain.current.createWorker(stage.loaderInfo.bytes, true);
					
					mainMessageChannel = worker.createMessageChannel(Worker.current);
					backMessageChannel = Worker.current.createMessageChannel(worker);	
					
					worker.setSharedProperty(MESSAGE_CHANNEL_UI, mainMessageChannel);
					worker.setSharedProperty(ASBackWorker.MESSAGE_CHANNEL_BACK, backMessageChannel);
					
					worker.start();

					uiSpeakerBA = new ByteArray();
					uiSpeakerBA.shareable = true;
					
					uiMutex = new Mutex();
					worker.setSharedProperty("uiMutex", uiMutex);
					worker.setSharedProperty("uiSpeakerBA", uiSpeakerBA);
					
					do
					{
						backSpeakerBA = worker.getSharedProperty("backSpeakerBA") as ByteArray;
					}
					while (backSpeakerBA == null);
					
					do
					{
						backMutex = worker.getSharedProperty("backMutex") as Mutex;
					}
					while (backMutex == null);
					
					workerToNotification = new WorkerToNotification(backSpeakerBA, backMutex, mainMessageChannel);
					
					NotificationCenter.setChanngel( backMessageChannel );
					NotificationCenter.setMutex(uiMutex);
					NotificationCenter.setByteArrayInfo( uiSpeakerBA );
				}
			}
		}
	}
}
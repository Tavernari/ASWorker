package
{
	import com.tavernari.asworker.ASWorker;
	import com.tavernari.asworker.notification.NotificationCenter;
	import com.tavernari.asworker.notification.NotificationCenterEvent;
	
	import flash.display.Sprite;
	
	public class ASWorkerDemo extends Sprite
	{
		private var asWorker:ASWorker;
		
		//BOTH AREA
		
		public function ASWorkerDemo()
		{
			//important know, all class start here will be replicated in all works.
			asWorker = new ASWorker(this.stage, uiWorkerStartedHandler, backWorkerStartedHandler);	
		}
		
		//BOTH AREA END
		
		//UI AREA START
		private function uiWorkerStartedHandler():void{
			//implement all class or calls for your UI
			
			NotificationCenter.addEventListener("FROM_BACK_EVENT_MESSAGE", onFromBackEventMessageHandler );
			
		}
		
		private function onFromBackEventMessageHandler(e:NotificationCenterEvent):void
		{
			trace(e.data);
			
			if(e.data == "completed job"){
				NotificationCenter.dispatchEventBetweenWorkers( new NotificationCenterEvent("NEXT_MESSAGE") );
			}
		}
		
		//UI AREA END
		
		//BACK AREA START
		
		private function backWorkerStartedHandler():void{
			//implement all class or calls for your BACK operations 
			NotificationCenter.addEventListener("NEXT_MESSAGE", uiCallForNextMessageHandler );
		}
		
		private function uiCallForNextMessageHandler():void
		{
			for(var i:int = 0; i < 15; ++i){
				NotificationCenter.dispatchEventBetweenWorkers( new NotificationCenterEvent("FROM_BACK_EVENT_MESSAGE", false, i) );
			}
			
			NotificationCenter.dispatchEventBetweenWorkers( new NotificationCenterEvent("FROM_BACK_EVENT_MESSAGE", false, "completed job") );
		}
		
		// BACK AREA END
	}
}
package com.tavernari.asworker.notification
{	
	import flash.events.Event;

	public class NotificationCenterEvent extends Event
	{
		private var _data:Object = new Object();
		public var canTraceEvent:Boolean = true;
		public var delayedInQueueProcessTime:int;
		
		public function NotificationCenterEvent(type:String, bubbles:Boolean=false, data:Object = null)
		{
			if(data != null){
				_data = data;
			}
			
			super(type, bubbles, true);
		}
		
		public function set data(value:Object):void
		{
			_data = value;
		}
		
		public function get data():Object
		{
			return _data;
		}
	}
}
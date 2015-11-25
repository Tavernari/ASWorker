package com.tavernari.asworker.notification
{	
	import flash.events.Event;

	public class NotificationCenterEvent extends Event
	{
		private var _data:Object;
		protected var _sendBy:int = NotificationCenter.BOTH;
		public var canTraceEvent:Boolean = true;
		public var delayedInQueueProcessTime:int;
		
		public function NotificationCenterEvent(type:String, bubbles:Boolean=false, data:Object = null)
		{
			_data = data;
			
			super(type, bubbles, true);
		}
		
		public function set sendBy(value:int):void
		{
			_sendBy = value;
		}
		
		public function get sendBy():int
		{
			return _sendBy;
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
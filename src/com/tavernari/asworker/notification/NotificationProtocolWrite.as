package com.tavernari.asworker.notification
{
	
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	import avmplus.getQualifiedClassName;

	internal class NotificationProtocolWrite
	{
		private var byteArray:ByteArray;
		private var event:NotificationCenterEvent;
		public function NotificationProtocolWrite(byteArray:ByteArray)
		{
			this.byteArray = byteArray;
		}
		
		public function configEventClass(event:NotificationCenterEvent):NotificationProtocolWrite{
			this.event = event;
			return this;
		}
		
		public function write():void{
			writeEventClass();
			writeEventType();
			wirteData();
		}
		
		private function wirteData():void
		{
			const tempBA:ByteArray = new ByteArray();
			
			const objectClass:String = getQualifiedClassName(event.data);
			
			if(objectClass.indexOf("::") != -1)
				registerClassAlias(objectClass.split("::")[1], getDefinitionByName(objectClass) as Class );
			else
				registerClassAlias(objectClass, getDefinitionByName(objectClass) as Class );
			
			byteArray.writeInt(objectClass.length);
			byteArray.writeUTFBytes(objectClass);
			
			tempBA.writeObject( event.data );
			byteArray.writeInt( tempBA.length );
			byteArray.writeObject( event.data );
		}
		
		private function writeEventType():void
		{
			byteArray.writeInt(event.type.length);
			byteArray.writeUTFBytes(event.type);
		}
		
		private function writeEventClass():void{
			const evtClass:String = getQualifiedClassName(event);
			
			byteArray.writeInt(evtClass.length);
			byteArray.writeUTFBytes(evtClass);
		}
		
	}
}
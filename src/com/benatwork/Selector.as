package com.benatwork
{
	import com.greensock.TweenLite;
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	public class Selector extends MovieClip
	{
		public var id:uint
		public var selectorTitle:String
		public var selectorText:TextField;
		public var actualWidth:Number = 0;
		public var tab:MovieClip;
		private var _activated:Boolean = false;
		
		public function Selector(id:uint, selectorTitle:String)
		{
			this.id = id;
			this.selectorTitle = selectorTitle;
			createText(selectorTitle);
			
		}
		private function createText(title:String){
			var univers:Font = new Univers();
			selectorText = new TextField();
			selectorText.selectable = false;
			selectorText.autoSize =  TextFieldAutoSize.LEFT;
			var selectorFormat:TextFormat = new TextFormat(univers.fontName,13,0xffba00);
			selectorText.defaultTextFormat = selectorFormat;
			selectorText.text = title;
			
			tab = drawTab(selectorText);
			addChild(tab);
			tab.alpha = 0;
			addChild(selectorText);
			selectorText.x += 10;
			selectorText.y += 0;
			
			addEventListener(MouseEvent.MOUSE_DOWN, onClick);
			selectorText.mouseEnabled = false;
			tab.buttonMode = true;
			
			
		}
		private function onClick(e:MouseEvent){
			dispatchEvent(new PlayerEvent(PlayerEvent.TRACK_SELECTED));
		}
		private function drawTab(tf:TextField):MovieClip{
			var t:MovieClip = new MovieClip();
			actualWidth = tf.textWidth+20;
			t.graphics.beginFill(0xFFFFFF,1);
			t.graphics.drawRoundRect(0,0,actualWidth, 50,10,10);
			t.graphics.endFill();
			
			
			return t;
			
		}
		public function activate(){
			_activated = true;
			TweenLite.to(tab, .5, {delay:.2,alpha:1});
		}
		public function deactivate(){
			_activated = false;
			TweenLite.to(tab, .2, {alpha:0});
		}

		public function get activated():Boolean
		{
			return _activated;
		}

	}
}
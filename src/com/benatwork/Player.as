package com.benatwork
{
	import com.greensock.TweenMax;
	import com.radioclouds.visualizer.models.Comment;
	import com.radioclouds.visualizer.models.Track;
	
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.text.Font;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class Player extends flash.display.MovieClip
	{
		private var _waveformLoader:Loader;
		private var _paused:Boolean = true;
		private var _seekPosition:Number = 0;
		private var _progressBar:MovieClip;
		private var _bufferProgress:MovieClip;
		private var _volume:MovieClip
		private var _volumeSlider:MovieClip
		private var _volumeHeight:Number;
		private var _waveformWidth:Number;
		private var _totalTime:Number;
		private var _seekMarker:MovieClip;
		private var _currentTime:Number;
		private var comments:Array = new Array();
		private var commentClips:Array = new Array();
		private var _playToggle:MovieClip;
		private var _activeComment:uint = 0;
		
		private var _volumeSliderPressed:Boolean = false;
		private var _playerOver:Boolean = false;
		private var _seekPressed:Boolean = false;
		private var univers:Font;
		
		var style:StyleSheet = new StyleSheet();
		
		public var _console:TextField
		
		public function Player() 
		{
			style.parseCSS("a:link{text-decoration: none; color:#ffba00;} a:hover{text-decoration: underline;}");
			

			_volume = volume;
			_volumeSlider = volume.slider;
			_volumeSlider.mouseEnabled = true;
			_volumeSlider.buttonMode = true;
			_volumeHeight = _volume.height;
			_waveformWidth = waveformHit.width;
			_seekMarker = seekMarker;
			_seekMarker.alpha = 0;
			_playToggle = playToggle;
			_console = console;
			var univers = new Univers();
			var selectorFormat:TextFormat = new TextFormat(univers.fontName,14,0xffffff);
			_console.defaultTextFormat = selectorFormat;
			selectorFormat.size = 14;
			_console.styleSheet = style;

			_volumeSlider.addEventListener(MouseEvent.MOUSE_DOWN, onVolumeSliderDown);

			waveformHit.addEventListener(MouseEvent.MOUSE_OVER, onPlayerOver);
			waveformHit.addEventListener(MouseEvent.MOUSE_OUT, onPlayerOut);
			waveformHit.addEventListener(MouseEvent.MOUSE_DOWN, onPlayerClick);
			waveformHit.addEventListener(MouseEvent.MOUSE_UP, onPlayerRelease);
			
			_playToggle.addEventListener(MouseEvent.MOUSE_DOWN, onPlayToggle);
			_playToggle.buttonMode = true;
			
			univers = new Univers();
		
	
			
		}
		public function initPlayer(trackData:Track){
			try{_waveformLoader.unload()}catch(e:Error){};
			_totalTime = trackData.duration;
			_waveformLoader = new Loader();
			_waveformLoader.visible = false;
			_waveformLoader.mouseEnabled = false;
			_progressBar = progress;
			_bufferProgress = bufferProgress;
			for each (var i in commentClips){
				removeChild(i);
			}
			_activeComment = 0;
			console.text = "";
			comments = new Array();
			commentClips = new Array();
			waveformHolder.addChild(_waveformLoader);
			_waveformLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onWaveformLoaded);
			_waveformLoader.load(new URLRequest(trackData.waveformUrl)); 
			
		}
		private function onWaveformLoaded(e:Event){
			_waveformLoader.width = this['waveform'].width;
			_waveformLoader.height = this['waveform'].height;
			_waveformLoader.visible = true;
			
			_waveformLoader.alpha = 0;
			TweenMax.to(_waveformLoader,0, {tint:0xffffff});
			TweenMax.to(_waveformLoader,1, {alpha:1});
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);	
			
		}
		private function onEnterFrame(e:Event){
			if(_volumeSliderPressed) {
				_volumeSlider.y = mouseY;
				if(_volumeSlider.y > _volumeHeight-_volumeSlider.height) _volumeSlider.y = _volumeHeight-_volumeSlider.height;
				if(_volumeSlider.y < 0) _volumeSlider.y = 0;
				dispatchEvent(new PlayerEvent(PlayerEvent.VOLUME_CHANGED));
			}
			if(_playerOver){
				_seekMarker.x = mouseX;
				checkCommentHit(true);
			} else {
				checkCommentHit();
			}
			if(_seekPressed){
				seekPosition = (mouseX/waveform.width)*_totalTime;
				if(mouseX > _waveformWidth) seekPosition = _totalTime;
				if(mouseX < 0) seekPosition = 0;
				dispatchEvent(new PlayerEvent(PlayerEvent.SEEK));
			}
			
		}

		
		public function changeSoundVolume(newVolume:Number){
			_volumeSlider.y = _volume.height-(_volume.height * newVolume);
		}
		public function getVolume():Number{
			var vol:Number =  (_volumeSlider.y/(_volume.height-_volumeSlider.height));
			TweenMax.to(waveform, .5, {alpha:1-vol+.1});
			TweenMax.to(bufferBg, .5, {colorTransform:{tint:0xffffff, tintAmount:vol}});
			return 1-vol;
		}
		
		private function onVolumeSliderDown(e:MouseEvent){
			_volumeSliderPressed = true;
			stage.addEventListener(MouseEvent.MOUSE_UP, onVolumeSliderOut);
		}
		private function onVolumeSliderOut(e:MouseEvent){
			_volumeSliderPressed = false;	
			removeEventListener(MouseEvent.MOUSE_UP, onVolumeSliderOut);
		}
		private function onPlayerOver(e:MouseEvent){
			_playerOver = true;
			TweenMax.to(_seekMarker, .5, {alpha:1});
		}
		private function onPlayerClick(e:MouseEvent){
			paused = false;
			_seekPressed = true;
			
		}
		private function onPlayerRelease(e:MouseEvent){
			_seekPressed = false;
		}
		private function onPlayerOut(e:MouseEvent){
			_playerOver = false;
			TweenMax.to(_seekMarker, .5, {alpha:0});
		}
		public function updateSeek(newTime:Number){
			_progressBar.scaleX = newTime/_totalTime;
			_currentTime = newTime;
			
		}
		public function updateVolume(newVolume:Number){
			_progressBar.scaleY = newVolume;
		}
		public function updateBuffer(newPercentage:Number){
			_bufferProgress.scaleX = newPercentage;
		}
		
		public function createComment(cdata:Comment){
			
			var cm:CommentMark = new CommentMark();
			cm.name = "comment"+comments.length;
			addChild(cm);
			comments.push(cdata);
			commentClips.push(cm);
			var n:Number = (cdata.timestamp/_totalTime)
			cm.x = n*(waveformHit.width);
		}
		private function checkCommentHit(isSeeking:Boolean = false){
			var nowTime:Number = isSeeking ? (mouseX/waveform.width)*_totalTime :_currentTime;
			var preScan:Number = isSeeking ? 5000 : 2000;
			var postScan:Number = isSeeking ? 5000 : 10000;
			
			for (var i = 0; i< comments.length; i++){
				
				var cm:Comment = comments[i] as Comment;
				var startTime:Number = cm.timestamp - preScan;
				var endTime:Number = cm.timestamp + postScan;
				commentClips[i].gotoAndStop(1);
				if (startTime < 0) startTime = 0;
				if (endTime > _totalTime) endTime = _totalTime;
				if( nowTime > startTime && nowTime < endTime && cm.body.charAt(0) != "@"){
					
					var words:Array = cm.body.split(" ");
					for (var k:uint = 0; k < words.length; k++){
						if(words[k].search("http") >= 0) {
							words[k] = createLink(words[k]);
						}
					}
					var comment:String = words.join(" ");
					
					_console.htmlText = createUserLink(cm.username,cm.userLink)+": "+comment;
					
					for (var j in comments){
						if(cm.timestamp == comments[j].timestamp){
							if(comments[j] != cm) {
								_console.htmlText = _console.text + ("\n"+createUserLink(comments[j].username,comments[j].userLink)+": "+comment);
							}
						}
					}
					commentClips[i].gotoAndStop(2);
					break;
				} 
				
			}

		}
		private function createLink(txt:String):String{
			var url:String = "<a href='"+txt+"' target='new'>"+txt+"</a>";
			return url;
		}
		private function createUserLink(userName:String,userLink:String):String{
			var url:String = "<a href='"+userLink+"' target='new'>"+userName+"</a>";
			return url;
		}
		private function onPlayToggle(e:MouseEvent){
			dispatchEvent(new PlayerEvent(PlayerEvent.PLAYTOGGLE));
		}

		public function get paused():Boolean
		{
			return _paused;
		}
		
		public function set paused(value:Boolean):void
		{
			value ? _playToggle.gotoAndStop(2) : _playToggle.gotoAndStop(1); 
			_paused = value;
		}
		public function get seekPosition():Number
		{
			return _seekPosition;
		}
		
		public function set seekPosition(value:Number):void
		{
			_seekPosition = value;
		}
		public function get progressBar():MovieClip
		{
			return _progressBar;
		}
		
		public function set progressBar(value:MovieClip):void
		{
			_progressBar = value;
		}

		public function get volumeSlider():MovieClip
		{
			return _volumeSlider;
		}

		public function set volumeSlider(value:MovieClip):void
		{
			_volumeSlider = value;
		}

	}
}
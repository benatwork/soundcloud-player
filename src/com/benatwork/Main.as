package com.benatwork
{
	import com.adobe.serialization.json.JSON;
	import com.benatwork.Player;
	import com.benatwork.PlayerEvent;
	import com.greensock.TweenLite;
	import com.radioclouds.visualizer.models.Comment;
	import com.radioclouds.visualizer.models.Track;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	

	public class Main extends Sprite
	{
		private var userID:String = "benatwork12";
		//private var trackID:String = "26448994";
		private var trackID:String = "28525938";
		private var secretToken:String = "s-z55wi";
		
		private var API_KEY:String = "d2e9027079da528682ce6fb2735a6b62";
		private var getTracksString = "https://api.soundcloud.com/tracks/"+trackID+".json?client_id="+API_KEY+"&secret_token="+secretToken;
		private var getCommentsString = "https://api.soundcloud.com/tracks/"+trackID+"/comments.json?client_id="+API_KEY+"&secret_token="+secretToken;;
		private var _sound:Sound;
		private var _soundChannel : SoundChannel;
		private var _isPaused:Boolean;
		private var _seekPosition:Number;
		private var _soundDuration:Number;
		private var _defaultVolume:Number = .8;
		private var _currentVolume:Number = _defaultVolume;
		private var _bufferProgress:MovieClip;
		private var comments:Array = new Array();
		private var player:Player
		private var isFinished:Boolean = false;
		
		public function Main()
		{
			player = new Player();
			player.x = 47;
			player.y = 74;
			player.alpha = 0;
			addChild(player);
			getTracks();
		}
		private function getTracks(){
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(getTracksString);
			loader.addEventListener(Event.COMPLETE, onTracksLoaded);
			loader.load(request);
		}
		private function getComments(){
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(getCommentsString);
			loader.addEventListener(Event.COMPLETE, onCommentsLoaded);
			loader.load(request);
		}

		private function onTracksLoaded(e:Event):void {   
			var loader:URLLoader = URLLoader(e.target);
			var jsonData:Object = JSON.decode(loader.data);
	
			var track = new Track(jsonData);
			getComments();
			playTrack(track);
			
			
		}
		private function onCommentsLoaded(e:Event){
			var loader:URLLoader = URLLoader(e.target);
			var jsonData:Array = JSON.decode(loader.data);
			
			for each (var i in jsonData){
				var comment = new Comment(i);
				comments.push(comment);
				player.createComment(comment);
			} 
			TweenLite.to(player, 1, {alpha:1});
		}
		private function playTrack(track : Track) : void {
			var url : String = track.streamUrl;
			
			player.initPlayer(track);
			player.addEventListener(PlayerEvent.VOLUME_CHANGED,changeSoundVolume);
			player.addEventListener(PlayerEvent.SEEK, onSeek);
			player.addEventListener(PlayerEvent.PLAYTOGGLE, playToggle);
			
			 _soundDuration = track.duration;
			_seekPosition = 0;
			
			_sound = new Sound();
			_sound.load(new URLRequest(tokenizeUrl(url)));
			_sound.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			_sound.addEventListener(ProgressEvent.PROGRESS, soundLoading);
			_soundChannel = _sound.play(_seekPosition);
			changeSoundVolume();
			player.changeSoundVolume(_defaultVolume);

			_soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
			
			removeEventListener(Event.ENTER_FRAME, onUpdate);
			addEventListener(Event.ENTER_FRAME, onUpdate);
			
			player.paused = _isPaused;
		}
		private function onLoadError(event : IOErrorEvent) : void {
			trace("error loading uri!");
		}
		private function soundLoading(e:ProgressEvent){
			var value:Number = e.bytesLoaded/e.bytesTotal;
			player.updateBuffer(value);
			
			
		}
		public function playToggle(e:PlayerEvent = null):void {
			if(isFinished) {
				player.seekPosition = 0;
				_isPaused = false
				player.paused = false;
				isFinished = false;
				player.dispatchEvent(new PlayerEvent(PlayerEvent.SEEK));
				
			} else {
				if(_isPaused){
					resumeSound();
				}else{
					stopSound();	
				}
			}
		}
		
		public function stopSound():void {
			if(_soundChannel) {
				_seekPosition = _soundChannel.position;
				_soundChannel.stop();
			}else {
				_seekPosition = 0;	
			}
			_isPaused = true;
			player.paused = _isPaused;
		}
		public function resumeSound():void {
			if(_soundChannel) {
				_soundChannel.stop();
				_soundChannel = _sound.play(_seekPosition);	
				changeSoundVolume();
				_soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
			}
			isFinished = false;
			_isPaused = false;
			player.paused = _isPaused;
		}
		private function changeSoundVolume(e:PlayerEvent = null) : void {
			var nv:Number = e ? player.getVolume() : player.getVolume() ;
			var transform:SoundTransform = new SoundTransform();
			transform.volume = nv;
			_soundChannel.soundTransform = transform;
			
		}
	
		private function onSoundComplete(e:Event){
			isFinished = true;
			stopSound();
			
		}
		
		private function onSeek(e:Event = null){
			_soundChannel.stop();
			_soundChannel = _sound.play(player.seekPosition);
			_seekPosition = player.seekPosition;
			_isPaused = false;
			changeSoundVolume()
			resumeSound();
		
		}
		
		private function onUpdate(e:Event){
			player.updateSeek(_soundChannel.position);
		}
		
		public function tokenizeUrl(url : String) : String {
			return url + (/\?/.test(url) ? "&" : "?") + "oauth_consumer_key=" + API_KEY;
		}
		
	
	}
}
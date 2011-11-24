package com.radioclouds.visualizer.models {

  /**
   * @author matas
   */
  public class Comment {
    public var timestamp : Number;
    public var isTimedComment : Boolean;
    public var iconUrl : String;
    public var body : String;
    public var username : String;
	public var userLink : String;
    public var createdAt : String;

    public function Comment(data : Object) {
			
      timestamp = Number(data.timestamp);
      //isTimedComment = !Boolean(data.timestamp.@nil.toString());
      //isReply = Boolean(uint(data["reply-to-id"]) > 0);
	  ;
	  var user:Object = data.user;
      iconUrl = user["avatar-url"];
      body = data.body;
      username = user.username;
	  userLink = user.permalink_url;
      createdAt = data["created-at"];
    }
  }
}

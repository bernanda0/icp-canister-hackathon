// Publisher
import List "mo:base/List";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Map "mo:map/Map";

actor Publisher {
  type Message = {
    topic : Text;
    value : Text;
  };

  type Subscriber = {
    topic : Text;
    clientId : Text;
    callback : shared Message -> ();
  };

  stable var subscribers = Map.new<Text, Subscriber>();

  public func subscribe(subscriber : Subscriber) {
    let key = subscriber.topic # "-" # subscriber.clientId;
    if (Map.contains(subscribers, Map.thash, key) == null) {
      Map.set(subscribers, Map.thash, key, subscriber);
      Debug.print(debug_show (subscribers.size()));
    } else {
      Debug.print(debug_show ("Subscriber already exists for topic: ", subscriber.topic, " and client ID: ", subscriber.clientId));
    };
  };

  public func publish(clientId : Text, message : Message) {
    let key = message.topic # "-" # clientId;
    let topicSubscriber = Map.get(subscribers, Map.thash, key);
    switch (topicSubscriber) {
      case (?subscriber) {
        subscriber.callback(message);
      };
      case null {
        Debug.print(debug_show("No subscriber found for topic: ", message.topic, " and clientId: ", clientId));
      };
    };
  };

};

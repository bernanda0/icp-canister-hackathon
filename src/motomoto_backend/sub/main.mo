// Subscriber

import Publisher "canister:pub";
import Debug "mo:base/Debug";
import Map "mo:map/Map";

actor Subscriber {
  type Message = {
    topic : Text;
    value : Text;
  };

  type MyData = {
    value : Text;
  };

  stable var data = Map.new<Text, MyData>();

  public func init(topic0 : Text, clientId0 : Text) {
    Publisher.subscribe({
      topic = topic0;
      clientId = clientId0;
      callback = updateMessage;
    });
  };

  public func updateMessage(message : Message) {
    let myData : MyData = { value = message.value };
    Map.set(data, Map.thash, message.topic, myData);
    Debug.print(debug_show(data));
    let getData = Map.get(data, Map.thash, message.topic);
    Debug.print(debug_show(?getData));
  };

  public query func getMessage(topic : Text) : async MyData {
    let myData = Map.get(data, Map.thash, topic);
    switch (myData) {
      case (?myDt) {
        Debug.print(debug_show("Found data for topic: ", topic));
        return myDt;
      };
      case null {
        Debug.print(debug_show("No data found for topic: ", topic));
        return { value = "" };
      };
    };
  };
}

// Publisher
import List "mo:base/List";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Bool "mo:base/Bool";
import Map "mo:map/Map";
import tp "../types";
import ut "../utils";
import DB "canister:db";

actor PubSub {
  stable var subscribers = Map.new<Text, tp.Ls<tp.BaggageReference>>();
  stable var lookup_subbag = Map.new<Text, Null>();

  public func subscribe(userId : Text, baggageRef : tp.BaggageReference) {
    // TODO : check if the baggage ref exists 
    var baggageIdExist = await DB.bagIdExists(baggageRef.baggage_id);
    if (not baggageIdExist) {
      return ();
    };

    let look_up_key = userId # "" # baggageRef.baggage_id;
    let look_up_exists = Map.has(lookup_subbag, Map.thash, look_up_key);
    if (look_up_exists) {
      return ();
    };
    Map.set(lookup_subbag, Map.thash, look_up_key, null);

    let key = userId;
    let subscribed_baggages = Map.get(subscribers, Map.thash, key);

    switch (subscribed_baggages) {
      case (?suffering) {
        var new_list = List.push(baggageRef, suffering);
        Map.set(subscribers, Map.thash, key, new_list);
      };
      // still empty
      case null {
        var new_list = List.nil<tp.BaggageReference>();
        new_list := List.push(baggageRef, new_list);
        Map.set(subscribers, Map.thash, key, new_list);
      };
    };
  };

  public func publish(message : tp.PublishMessage) : async tp.Res<Text, Text> {
    let key = message.b_user_id;
    let subscribed_baggages = Map.get(subscribers, Map.thash, key);

    switch (subscribed_baggages) {
      case (?cry) {
        for (bRef in List.toIter(cry)) {
          if (bRef.baggage_id == message.b_key.baggage_id) {
            var res = await bRef.callback(message.b_key, message.b_payload);
            if (res) {
              return #ok("Update Success");
            };
            return #err("Failed to update baggage");
          };
          return #err("Baggage not found");
        };
        return #err("Baggage not found");
      };
      case null {
        return #err("No subscribed bag found");
      };
    };
  };

  public func init(userId : Text, baggageId : Text) {
    subscribe(
      userId,
      {
        baggage_id = baggageId;
        callback = DB.updateBaggageEvent;
      },
    );
  };

  public query func getSubscribedBag(userId : Text) : async [Text] {
    let subscribed_baggages = Map.get(subscribers, Map.thash, userId);
    switch (subscribed_baggages) {
      case (?cry) {
        var buffer_id = Buffer.Buffer<Text>(3);

        for (bRef in List.toIter(cry)) {
          buffer_id.add(bRef.baggage_id);
        };

        return Buffer.toArray(buffer_id);
      };
      case null {
        return [];
      };
    };
  };

  // reset pub sub data
  public func resetSubscriberData() : async Text {
    subscribers := Map.new<Text, tp.Ls<tp.BaggageReference>>();
    return debug_show("Subs data reset");
  };

  // reset pub sub data
  public func resetLookUp() : async Text {
    lookup_subbag := Map.new<Text, Null>();
    return debug_show("Lookup data reset");
  };

};

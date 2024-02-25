import React, { useEffect, useState } from 'react';
import { testing } from "../../declarations/testing"
import { sub } from "../../declarations/sub"

function App() {
  const [counter, setCounter] = useState('');
  const [name, setName] = useState('');
  const [greeting, setGreeting] = useState('');
  const [msg, setMsg] = useState('');
  const topic = "bag";

  useEffect(() => {
    const getInitialValue = async () => {
      const initValue = await testing.getValue();
      setCounter(String(initValue));
    }

    const subscribe = async () => {
      sub.init(topic, "xw1").then( () => {
        console.log("subscribed to bag");
      }).catch( (err) => { 
        console.log("error: ", err);
        setMsg("error");
      });
      // I need to call the callback everytime there's data changing
    }

    getInitialValue()
    subscribe()
  }, [])



  useEffect(() => {
    const getTopicMessage = async () => {
      sub.getMessage(topic).then( (data) => {
        setMsg(data.value);
      }).catch( (err) => { 
        console.log("error: ", err);
        setMsg("error");
      });
    }

    // call getBagCount() every 2 seconds
    const interval = setInterval(getTopicMessage, 5000);
    return () => clearInterval(interval);

  }, [msg])

  const incrementCounter = async () => {
    const newValue = await testing.inc();
    setCounter(String(newValue));
  };

  const greetUser = async () => {
    const message = await testing.greet(name);
    setGreeting(message);
  };

  return (
    <div>
      <h1>Internet Computer (IC) Demo</h1>
      <div>
        <h2>Message: {msg}</h2>
        <h2>Counter Value: {counter}</h2>
        <button onClick={incrementCounter}>Increment Counter</button>
      </div>
      <div>
        <h2>Greet User</h2>
        <input type="text" value={name} onChange={(e) => setName(e.target.value)} />
        <button onClick={greetUser}>Greet</button>
        <p>{greeting}</p>
      </div>
    </div>
  );
}

export default App;

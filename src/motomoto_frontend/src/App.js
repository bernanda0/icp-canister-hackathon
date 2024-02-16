import React, { useEffect, useState } from 'react';
import { motomoto_backend } from "../../declarations/motomoto_backend"

function App() {
  const [counter, setCounter] = useState('');
  const [name, setName] = useState('');
  const [greeting, setGreeting] = useState('');

  useEffect(()=> {
    const getInitialValue = async () =>  {
      const initValue = await motomoto_backend.getValue();
      setCounter(String(initValue));
    }

    getInitialValue()
  }, [])

  const incrementCounter = async () => {
    const newValue = await motomoto_backend.inc();
    setCounter(String(newValue));
  };

  const greetUser = async () => {
    const message = await motomoto_backend.greet(name);
    setGreeting(message);
  };

  return (
    <div>
      <h1>Internet Computer (IC) Demo</h1>
      <div>
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

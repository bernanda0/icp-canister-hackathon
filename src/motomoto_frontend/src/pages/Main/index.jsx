import { useEffect, useState } from "react";
import { useAuth } from "../../auth/AuthProvider";
import { be } from "../../../../declarations/be";

const tatumAPIKey = process.env.TATUM_API_KEY;

export default function MainPage() {
  const { user, hasSession, logout } = useAuth();
  const [baggageList, setBaggageList] = useState([]);
  const [baggageId, setBaggageId] = useState("");
  const [displayBaggage, setDisplayBaggage] = useState(false);
  const [rerender, setRerender] = useState(false);
  const [image, setImage] = useState(null);
  const [CID, setCID] = useState("");
  const [imageUrl, setImageUrl] = useState("");

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    setImage(file);
  };

  const handleUpload = async () => {
    if (!image) {
      alert("Please select an image to upload");
      return;
    }

    const formData = new FormData();
    formData.append("file", image);

    try {
      const response = await fetch("https://api.tatum.io/v3/ipfs", {
        method: "POST",
        headers: {
          "x-api-key": tatumAPIKey, // Replace <mykey> with your API key
        },
        body: formData,
      });

      const data = await response.text();
      console.log("IPFS Response:", data);

      if (response.ok) {
        setCID(JSON.parse(data).ipfsHash);
      }
    } catch (error) {
      console.error("Error uploading image:", error);
    }
  };

  const handleFetchImage = async () => {
    try {
      const response = await fetch(`https://api.tatum.io/v3/ipfs/${CID}`, {
        method: "GET",
        headers: {
          "x-api-key": tatumAPIKey,
        },
      });

      if (!response.ok) {
        throw new Error("Failed to fetch image");
      }

      const blob = await response.blob();
      const url = URL.createObjectURL(blob);
      setImageUrl(url);
    } catch (error) {
      console.error("Error fetching image:", error);
    }
  };

  const subscribe = async () => {
    be.init(user, baggageId).then(() => {
      setRerender(!rerender);
      console.log("subscribed");
    });
  };

  useEffect(() => {
    const getBaggageList = async () => {
      be.getSubscribedBag(user).then((baggageLs) => {
        setBaggageList(baggageLs);
      });
    };

    getBaggageList();
  }, [user, rerender]);

  return (
    <div>
      <h1>Internet Computer (IC) Demo</h1>
      <div>
        <h2>User ID: {user}</h2>
        <h2>Authenticated : {hasSession ? "TRUE" : "FALSE"}</h2>

        <div>
          <h2>Image Uploader</h2>
          <input type="file" accept="image/*" onChange={handleImageChange} />
          <button onClick={handleUpload}>Upload Image</button>
          <h3>CID : {CID}</h3>
          <button onClick={handleFetchImage}>Fetch Image</button>
          {imageUrl && (
            <div>
              <h3>Image Preview</h3>
              <img src={imageUrl} alt="wkwk" style={{ maxWidth: "25%" }} />
            </div>
          )}
        </div>

        <button onClick={logout}>Logout</button>
      </div>
    </div>
  );
}

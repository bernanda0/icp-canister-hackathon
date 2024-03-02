import { AuthProvider } from "./auth/AuthProvider";
import { Navigate, Outlet, Route, Routes } from "react-router-dom";
import { useAuth } from "./auth/AuthProvider";
import LoginPage from "./pages/LoginPage";
import MainPage from "./pages/Main";
import NotFoundPage from "./pages/404";

export default function App() {
  return (
    <>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route element={<PrivateWrapper />}>
            <Route path="/home" element={<MainPage />} />
            <Route path="/" element={<Navigate to="home" />} />
          </Route>
          <Route path="/404" element={<NotFoundPage />} />
          <Route path="*" element={<Navigate to="404" />} />
        </Routes>
      </AuthProvider>
    </>
  );
}

const PrivateWrapper = () => {
  const { user } = useAuth();
  return user ? <Outlet /> : <Navigate to="/login" />;
};

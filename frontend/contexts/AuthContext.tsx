'use client';

import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { useRouter } from 'next/navigation';
import { authApi, getToken, removeToken } from '@/lib/api';
import { decodeToken, isTokenExpired } from '@/lib/jwt';
import type { User, LoginRequest, SignupRequest } from '@/types/api';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (credentials: LoginRequest) => Promise<void>;
  signup: (data: SignupRequest) => Promise<void>;
  logout: () => Promise<void>;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  // Check if user is authenticated on mount
  useEffect(() => {
    async function checkAuth() {
      const token = getToken();
      if (token) {
        // Check if token is expired
        if (isTokenExpired(token)) {
          removeToken();
          setLoading(false);
          return;
        }

        // Try to get current user from API
        try {
          const currentUser = await authApi.getCurrentUser();
          setUser(currentUser);
        } catch (error: unknown) {
          const err = error as { error?: string; status?: number; message?: string };
          const isAuthError = err?.status === 401 || err?.error === 'Unauthorized';
          const isNetworkError = err?.error === 'Network error' || err?.message?.includes('Unable to connect');
          if (isAuthError) {
            removeToken();
          } else if (!isNetworkError) {
            const decoded = decodeToken(token);
            if (!decoded) removeToken();
          }
        }
      }
      setLoading(false);
    }
    
    checkAuth();
  }, []);

  const login = async (credentials: LoginRequest) => {
    try {
      const response = await authApi.login(credentials);
      setUser(response.user);
      router.push('/dashboard');
    } catch (error) {
      throw error;
    }
  };

  const signup = async (data: SignupRequest) => {
    try {
      const response = await authApi.signup(data);
      setUser(response.user);
      router.push('/dashboard');
    } catch (error) {
      throw error;
    }
  };

  const logout = async () => {
    try {
      await authApi.logout();
      setUser(null);
      removeToken();
      router.push('/login');
    } catch (error) {
      // Even if logout fails, clear local state
      setUser(null);
      removeToken();
      router.push('/login');
    }
  };

  const isAuthenticated = !!getToken();

  return (
    <AuthContext.Provider
      value={{
        user,
        loading,
        login,
        signup,
        logout,
        isAuthenticated,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

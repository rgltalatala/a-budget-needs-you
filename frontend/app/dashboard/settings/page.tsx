'use client';

import { useState, FormEvent } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Error } from '@/components/ui/Error';
import { authApi } from '@/lib/api';
import { isDemoEmail } from '@/lib/demo';
import type { ApiError } from '@/types/api';

function validatePassword(pwd: string): string | null {
  if (pwd.length < 12) return 'Password must be at least 12 characters';
  if (!/\d/.test(pwd)) return 'Password must include at least one number';
  if (!/[!@#$%^&*(),.?":{}|<>]/.test(pwd)) return 'Password must include at least one special character';
  return null;
}

export default function SettingsPage() {
  const { user } = useAuth();
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [newPasswordConfirmation, setNewPasswordConfirmation] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const isDemo = user ? isDemoEmail(user.email) : false;

  const handleChangePassword = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    setMessage(null);

    const passwordError = validatePassword(newPassword);
    if (passwordError) {
      setError(passwordError);
      return;
    }
    if (newPassword !== newPasswordConfirmation) {
      setError('New passwords do not match');
      return;
    }

    setIsLoading(true);
    try {
      await authApi.changePassword({
        current_password: currentPassword,
        password: newPassword,
        password_confirmation: newPasswordConfirmation,
      });
      setMessage('Password updated successfully.');
      setCurrentPassword('');
      setNewPassword('');
      setNewPasswordConfirmation('');
    } catch (err) {
      const apiError = err as ApiError;
      setError(
        typeof apiError.message === 'string'
          ? apiError.message
          : apiError.message?.[0] || apiError.error || 'Failed to change password'
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-bold text-gray-900">Settings</h1>

      <section className="bg-white shadow rounded-lg p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-1">Privacy</h2>
        <p className="text-sm text-gray-600 mb-6">
          Manage your account and password.
        </p>

        <div className="border-t border-gray-200 pt-6">
          <h3 className="text-base font-medium text-gray-900 mb-2">Change password</h3>
          {isDemo ? (
            <div className="rounded-md bg-amber-50 border border-amber-200 p-4 text-sm text-amber-800">
              Password change is disabled for demo accounts so that other users can sign in with the same credentials.
              Create your own account to change your password.
            </div>
          ) : (
            <form onSubmit={handleChangePassword} className="max-w-md space-y-4 mt-2">
              {error && <Error>{error}</Error>}
              {message && (
                <div className="rounded-md bg-green-50 p-3 text-sm text-green-800">
                  {message}
                </div>
              )}
              <Input
                label="Current password"
                type="password"
                autoComplete="current-password"
                required
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                disabled={isLoading}
              />
              <Input
                label="New password"
                type="password"
                autoComplete="new-password"
                required
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                disabled={isLoading}
                minLength={12}
              />
              <Input
                label="Confirm new password"
                type="password"
                autoComplete="new-password"
                required
                value={newPasswordConfirmation}
                onChange={(e) => setNewPasswordConfirmation(e.target.value)}
                disabled={isLoading}
                minLength={12}
              />
              <Button type="submit" isLoading={isLoading}>
                Update password
              </Button>
            </form>
          )}
        </div>
      </section>
    </div>
  );
}

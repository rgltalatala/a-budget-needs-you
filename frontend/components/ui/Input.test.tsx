import { describe, test, expect } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Input } from './Input';

describe('Input', () => {
  test('renders with label', () => {
    render(<Input label="Email address" />);
    expect(screen.getByLabelText(/email address/i)).toBeInTheDocument();
  });

  test('renders input that accepts value change', () => {
    render(<Input label="Name" />);
    const input = screen.getByLabelText(/name/i);
    fireEvent.change(input, { target: { value: 'Jane' } });
    expect(input).toHaveValue('Jane');
  });

  test('can be disabled', () => {
    render(<Input label="Field" disabled />);
    expect(screen.getByLabelText(/field/i)).toBeDisabled();
  });

  test('shows error message when error prop is set', () => {
    render(<Input label="Email" error="Invalid email" />);
    expect(screen.getByText(/invalid email/i)).toBeInTheDocument();
  });
});

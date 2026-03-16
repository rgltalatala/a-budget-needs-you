import { describe, test, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { Error } from './Error';

describe('Error', () => {
  test('renders message', () => {
    render(<Error>Something went wrong</Error>);
    expect(screen.getByText(/something went wrong/i)).toBeInTheDocument();
  });
});

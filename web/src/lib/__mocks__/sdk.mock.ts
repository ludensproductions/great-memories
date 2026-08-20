import * as sdk from '@great-memories/sdk';
import type { Mock, MockedObject } from 'vitest';

// eslint-disable-next-line unicorn/no-top-level-side-effects
vi.mock('@great-memories/sdk', async (originalImport) => {
  const module = await originalImport<typeof import('@great-memories/sdk')>();

  const mocks: Record<string, Mock> = {};
  for (const [key, value] of Object.entries(module)) {
    if (typeof value === 'function') {
      mocks[key] = vi.fn();
    }
  }

  const mock = { ...module, ...mocks };
  return { ...mock, default: mock };
});

export const sdkMock = sdk as MockedObject<typeof sdk>;

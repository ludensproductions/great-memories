import { readFileSync } from 'node:fs';
import { greatMemoriesCli } from 'src/utils';
import { describe, expect, it } from 'vitest';

const pkg = JSON.parse(readFileSync('../packages/cli/package.json', 'utf8'));

describe(`great-memories --version`, () => {
  describe('great-memories --version', () => {
    it('should print the cli version', async () => {
      const { stdout, stderr, exitCode } = await greatMemoriesCli(['--version']);
      expect(stdout).toEqual(pkg.version);
      expect(stderr).toEqual('');
      expect(exitCode).toBe(0);
    });
  });

  describe('great-memories -V', () => {
    it('should print the cli version', async () => {
      const { stdout, stderr, exitCode } = await greatMemoriesCli(['-V']);
      expect(stdout).toEqual(pkg.version);
      expect(stderr).toEqual('');
      expect(exitCode).toBe(0);
    });
  });
});

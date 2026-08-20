import { StorageCore } from 'src/cores/storage.core';
import { vitest } from 'vitest';

vitest.mock('src/constants', () => ({
  IWorker: 'IWorker',
}));

describe('StorageCore', () => {
  describe('isManagedMediaPath', () => {
    beforeAll(() => {
      StorageCore.setMediaLocation('/photos');
    });

    it('should return true for APP_MEDIA_LOCATION path', () => {
      const greatMemoriesPath = '/photos';
      expect(StorageCore.isManagedMediaPath(greatMemoriesPath)).toBe(true);
    });

    it('should return true for paths within the APP_MEDIA_LOCATION', () => {
      const greatMemoriesPath = '/photos/new/';
      expect(StorageCore.isManagedMediaPath(greatMemoriesPath)).toBe(true);
    });

    it('should return false for paths outside the APP_MEDIA_LOCATION and same starts', () => {
      const nonManagedMediaPath = '/photos_new';
      expect(StorageCore.isManagedMediaPath(nonManagedMediaPath)).toBe(false);
    });

    it('should return false for paths outside the APP_MEDIA_LOCATION', () => {
      const nonManagedMediaPath = '/some/other/path';
      expect(StorageCore.isManagedMediaPath(nonManagedMediaPath)).toBe(false);
    });
  });
});
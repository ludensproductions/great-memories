import { getAppVersionFromUA } from 'src/utils/request';

describe(getAppVersionFromUA.name, () => {
  describe('great memories format', () => {
    it('should get the app version for android', () => {
      expect(getAppVersionFromUA('great-memories-android/1.123.4')).toEqual('1.123.4');
    });

    it('should get the app version for ios', () => {
      expect(getAppVersionFromUA('great-memories-ios/1.123.4')).toEqual('1.123.4');
    });

    it('should get the app version for unknown', () => {
      expect(getAppVersionFromUA('great-memories-unknown/1.123.4')).toEqual('1.123.4');
    });
  });

  describe('current great-memories format', () => {
    it('should get the app version for android', () => {
      expect(getAppVersionFromUA('great-memories-android/1.123.4')).toEqual('1.123.4');
    });

    it('should get the app version for ios', () => {
      expect(getAppVersionFromUA('great-memories-ios/1.123.4')).toEqual('1.123.4');
    });

    it('should get the app version for unknown', () => {
      expect(getAppVersionFromUA('great-memories-unknown/1.123.4')).toEqual('1.123.4');
    });
  });

  describe('underscore formats', () => {
    it('should get the app version from the great memories android format', () => {
      expect(getAppVersionFromUA('GreatMemories_Android_1.123.4')).toEqual('1.123.4');
    });

    it('should get the app version from the great memories ios format', () => {
      expect(getAppVersionFromUA('GreatMemories_iOS_1.123.4')).toEqual('1.123.4');
    });

    it('should get the app version from the great memories unknown format', () => {
      expect(getAppVersionFromUA('GreatMemories_Unknown_1.123.4')).toEqual('1.123.4');
    });

    it('should get the app version from the old android format', () => {
      expect(getAppVersionFromUA('Great Memories_Android_1.123.4')).toEqual('1.123.4');
    });

    it('should get the app version from the old ios format', () => {
      expect(getAppVersionFromUA('Great Memories_iOS_1.123.4')).toEqual('1.123.4');
    });

    it('should get the app version from the old unknown format', () => {
      expect(getAppVersionFromUA('Great Memories_Unknown_1.123.4')).toEqual('1.123.4');
    });
  });
});
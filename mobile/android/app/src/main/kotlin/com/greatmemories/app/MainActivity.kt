package com.greatmemories.app

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.ext.SdkExtensions
import com.greatmemories.app.background.BackgroundEngineLock
import com.greatmemories.app.background.BackgroundWorkerApiImpl
import com.greatmemories.app.background.BackgroundWorkerFgHostApi
import com.greatmemories.app.background.BackgroundWorkerLockApi
import com.greatmemories.app.connectivity.ConnectivityApi
import com.greatmemories.app.connectivity.ConnectivityApiImpl
import com.greatmemories.app.core.HttpClientManager
import com.greatmemories.app.core.GreatMemoriesPlugin
import com.greatmemories.app.core.NetworkApiPlugin
import me.albemala.native_video_player.NativeVideoPlayerPlugin
import com.greatmemories.app.images.LocalImageApi
import com.greatmemories.app.images.LocalImagesImpl
import com.greatmemories.app.images.RemoteImageApi
import com.greatmemories.app.images.RemoteImagesImpl
import com.greatmemories.app.permission.PermissionApi
import com.greatmemories.app.permission.PermissionApiImpl
import com.greatmemories.app.sync.NativeSyncApi
import com.greatmemories.app.sync.NativeSyncApiImpl26
import com.greatmemories.app.sync.NativeSyncApiImpl30
import com.greatmemories.app.viewintent.ViewIntentPlugin
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    registerPlugins(this, flutterEngine)
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    setIntent(intent)
  }

  companion object {
    fun registerPlugins(ctx: Context, flutterEngine: FlutterEngine) {
      HttpClientManager.initialize(ctx)
      NativeVideoPlayerPlugin.dataSourceFactory = HttpClientManager::createDataSourceFactory
      flutterEngine.plugins.add(NetworkApiPlugin())

      val messenger = flutterEngine.dartExecutor.binaryMessenger
      val backgroundEngineLockImpl = BackgroundEngineLock(ctx)
      BackgroundWorkerLockApi.setUp(messenger, backgroundEngineLockImpl)
      val nativeSyncApiImpl =
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R || SdkExtensions.getExtensionVersion(Build.VERSION_CODES.R) < 1) {
          NativeSyncApiImpl26(ctx)
        } else {
          NativeSyncApiImpl30(ctx)
        }
      val permissionApiImpl = PermissionApiImpl(ctx)
      NativeSyncApi.setUp(messenger, nativeSyncApiImpl)
      PermissionApi.setUp(messenger, permissionApiImpl)
      LocalImageApi.setUp(messenger, LocalImagesImpl(ctx))
      RemoteImageApi.setUp(messenger, RemoteImagesImpl(ctx))

      BackgroundWorkerFgHostApi.setUp(messenger, BackgroundWorkerApiImpl(ctx))
      ConnectivityApi.setUp(messenger, ConnectivityApiImpl(ctx))

      flutterEngine.plugins.add(ViewIntentPlugin())
      flutterEngine.plugins.add(backgroundEngineLockImpl)
      flutterEngine.plugins.add(nativeSyncApiImpl)
      flutterEngine.plugins.add(permissionApiImpl)
    }

    fun cancelPlugins(flutterEngine: FlutterEngine) {
      val nativeApi =
        flutterEngine.plugins.get(NativeSyncApiImpl26::class.java) as GreatMemoriesPlugin?
          ?: flutterEngine.plugins.get(NativeSyncApiImpl30::class.java) as GreatMemoriesPlugin?
      nativeApi?.detachFromEngine()
      val permissionApi = flutterEngine.plugins.get(PermissionApiImpl::class.java) as GreatMemoriesPlugin?
      permissionApi?.detachFromEngine()
    }
  }
}

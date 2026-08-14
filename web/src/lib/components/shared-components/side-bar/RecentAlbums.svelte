<script lang="ts">
  import { authManager } from '$lib/managers/auth-manager.svelte';
  import { Route } from '$lib/route';
  import { userInteraction } from '$lib/stores/user.svelte';
  import { getAssetMediaUrl } from '$lib/utils';
  import { handleError } from '$lib/utils/handle-error';
  import { getAllAlbums } from '@great-memories/sdk';
  import { t } from 'svelte-i18n';

  let albums = $state(userInteraction.recentAlbums);

  const refreshAlbums = async () => {
    if (!authManager.authenticated) {
      albums = [];
      return;
    }

    try {
      const allAlbums = await getAllAlbums({});
      albums = allAlbums.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()).slice(0, 3);
      userInteraction.recentAlbums = albums;
    } catch (error) {
      handleError(error, $t('failed_to_load_assets'));
    }
  };

  $effect(() => {
    if (!authManager.authenticated) {
      albums = [];
      return;
    }

    if (!userInteraction.recentAlbums) {
      void refreshAlbums();
    }
  });
</script>

{#each albums as album (album.id)}
  <a
    href={Route.viewAlbum(album)}
    title={album.albumName}
    class="flex w-full place-items-center justify-between gap-4 rounded-e-full py-3 ps-10 transition-[padding] delay-100 duration-100 hover:cursor-pointer hover:bg-subtle hover:text-great-memories-primary group-hover:sm:px-10 md:px-10 dark:text-great-memories-dark-fg dark:hover:bg-great-memories-dark-gray dark:hover:text-great-memories-dark-primary"
  >
    <div>
      <div
        class="size-6 rounded-sm bg-gray-200 bg-cover dark:bg-gray-600"
        style={album.albumThumbnailAssetId
          ? `background-image:url('${getAssetMediaUrl({ id: album.albumThumbnailAssetId })}')`
          : ''}
      ></div>
    </div>
    <div class="grow truncate text-sm font-medium">
      {album.albumName}
    </div>
  </a>
{/each}

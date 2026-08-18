<script lang="ts">
  import ServerAboutItem from '$lib/components/ServerAboutItem.svelte';
  import { locale } from '$lib/stores/preferences.store';
  import { type ServerAboutResponseDto, type ServerVersionHistoryResponseDto } from '@great-memories/sdk';
  import { mdiClose } from '@mdi/js';
  import { Alert, IconButton, Label, Modal, ModalBody } from '@immich/ui';
  import { DateTime } from 'luxon';
  import { t } from 'svelte-i18n';

  interface Props {
    onClose: () => void;
    info: ServerAboutResponseDto;
    versions: ServerVersionHistoryResponseDto[];
  }

  let { onClose, info, versions }: Props = $props();
</script>

<Modal {onClose}>
  <ModalBody>
    <div class="mb-4 flex items-center justify-between gap-3 border-b border-gray-200 pb-3 dark:border-white/10">
      <div class="flex items-center gap-3">
        <img src="/manifest-icon-512.maskable.png?v=great-memories-20260729" alt="Great Memories logo" class="h-8 w-8" />
        <div class="flex flex-col">
          <p class="text-lg font-semibold tracking-tight text-dark/90 dark:text-white">{$t('about')}</p>
          <p class="text-sm text-primary">Great Memories</p>
        </div>
      </div>

      <IconButton
        shape="round"
        color="secondary"
        variant="ghost"
        icon={mdiClose}
        aria-label={$t('close')}
        onclick={onClose}
      />
    </div>

    <div class="flex flex-col gap-4 sm:grid sm:grid-cols-2">
      {#if info.sourceRef === 'main' && info.repository === 'ludensproductions/immich'}
        <Alert color="warning" title={$t('main_branch_warning')} class="col-span-full" size="small" />
      {/if}

      <ServerAboutItem id="great-memories" title="Great Memories" version={info.version} versionHref={info.versionUrl} />
      <ServerAboutItem id="exif" title="ExifTool" version={info.exiftool} />
      <ServerAboutItem id="nodejs" title="Node.js" version={info.nodejs} />
      <ServerAboutItem id="libvips" title="Libvips" version={info.libvips} />
      <ServerAboutItem
        id="imagemagick"
        title="ImageMagick"
        version={info.imagemagick}
        class={(info.imagemagick?.length || 0) > 10 ? 'col-span-2' : ''}
      />
      <ServerAboutItem
        id="ffmpeg"
        title="FFmpeg"
        version={info.ffmpeg}
        class={(info.ffmpeg?.length || 0) > 10 ? 'col-span-2' : ''}
      />

      {#if info.sourceRef && info.sourceCommit && info.sourceUrl}
        <ServerAboutItem
          id="source"
          title={$t('source')}
          version="{info.sourceRef}@{info.sourceCommit.slice(0, 9)}"
          versionHref={info.sourceUrl}
        />
      {/if}

      {#if info.build && info.buildUrl}
        <ServerAboutItem id="build" title={$t('build')} version={info.build} versionHref={info.buildUrl} />
      {/if}

      {#if info.buildImage && info.buildImageUrl}
        <ServerAboutItem
          id="build-image"
          title={$t('build_image')}
          version={info.buildImage}
          versionHref={info.buildImageUrl}
        />
      {/if}

      <div class="col-span-full">
        <Label size="small" color="primary" for="version-history">{$t('version_history')}</Label>
        <ul id="version-history" class="list-none">
          {#each versions.slice(0, 5) as item (item.id)}
            {@const createdAt = DateTime.fromISO(item.createdAt)}
            <li>
              <span
                class="pb-2 text-xs great-memories-form-label"
                id="version-history"
                title={createdAt.toLocaleString(DateTime.DATETIME_SHORT_WITH_SECONDS, { locale: $locale })}
              >
                {$t('version_history_item', {
                  values: {
                    version: item.version,
                    date: createdAt.toLocaleString(
                      {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric',
                      },
                      { locale: $locale },
                    ),
                  },
                })}
              </span>
            </li>
          {/each}
        </ul>
      </div>
    </div>
  </ModalBody>
</Modal>
<script lang="ts">
  import StorageTemplateSettings from '$lib/components/admin-settings/StorageTemplateSettings.svelte';
  import FormatMessage from '$lib/elements/FormatMessage.svelte';
  import { authManager } from '$lib/managers/auth-manager.svelte';
</script>

<div class="flex flex-col">
  <p>
    <FormatMessage key="admin.storage_template_onboarding_description_v2">
      {#snippet children({ message })}
        {message}
      {/snippet}
    </FormatMessage>
  </p>

  {#if authManager.authenticated}
    <StorageTemplateSettings minified duration={0} saveOnClose />
  {/if}
</div>

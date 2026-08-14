<script lang="ts">
  import empty1Url from '$lib/assets/empty-1.svg';

  interface Props {
    onClick?: undefined | (() => unknown);
    text: string;
    fullWidth?: boolean;
    src?: string;
    title?: string;
    class?: string;
  }

  let { onClick = undefined, text, fullWidth = false, src = empty1Url, title, class: className }: Props = $props();

  let width = $derived(fullWidth ? 'w-full' : 'w-1/2');

  const hoverClasses = onClick
    ? `border dark:border-great-memories-dark-gray hover:bg-great-memories-primary/5 dark:hover:bg-great-memories-dark-primary/25`
    : '';
</script>

<!-- svelte-ignore a11y_no_static_element_interactions -->
<svelte:element
  this={onClick ? 'button' : 'div'}
  onclick={onClick}
  class="{width} {className} flex flex-col place-content-center place-items-center rounded-3xl bg-gray-50 p-5 dark:bg-great-memories-dark-gray {hoverClasses}"
>
  <img {src} alt="" width="500" draggable="false" />

  {#if title}
    <h2 class="my-4 text-xl font-medium">{title}</h2>
  {/if}
  <p class="text-great-memories-text-gray-500 text-center font-light dark:text-great-memories-dark-fg">{text}</p>
</svelte:element>

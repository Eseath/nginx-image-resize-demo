<template>
    <app-spinner v-if="waiting" class="m-auto" />
    <div v-else class="flex flex-col gap-8 h-full">
        <div class="flex gap-8">
            <div>
                <div class="font-bold text-xs uppercase">Format</div>
                <ul class="flex gap-2">
                    <li
                        v-for="format in formats"
                        class="cursor-pointer underline-offset-8 hover:underline"
                        :class="{ 'underline text-indigo-300': selectedFormat === format }"
                        @click="selectedFormat = format"
                    >
                        {{ format }}
                    </li>
                </ul>
            </div>
            <div>
                <div class="font-bold text-xs uppercase">Resolution</div>
                <ul class="flex gap-2">
                    <li
                        v-for="resolution in resolutions"
                        class="cursor-pointer underline-offset-8 hover:underline"
                        :class="{ 'underline text-indigo-300': selectedResolution === resolution }"
                        @click="selectedResolution = resolution"
                    >
                        {{ resolution }}
                    </li>
                </ul>
            </div>
            <div>
                <div class="font-bold text-xs uppercase">Orientation</div>
                <ul class="flex gap-2">
                    <li
                        v-for="orientation in orientations"
                        class="cursor-pointer underline-offset-8 hover:underline"
                        :class="{ 'underline text-indigo-300': selectedOrientation === orientation }"
                        @click="selectedOrientation = orientation"
                    >
                        {{ orientation }}
                    </li>
                </ul>
            </div>
            <div class="ml-auto">
                <button
                    type="button"
                    class="flex justify-center rounded-md transition-colors bg-indigo-500 hover:bg-indigo-500/80 px-3 py-1.5 text-sm font-semibold leading-6 text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                    @click="reloadWithoutCache"
                >
                    Reload images
                </button>
            </div>
        </div>

        <div>
            <div>
                Original image:
                <a :href="originalImage" target="_blank">{{ originalImage }}</a>
            </div>
            <div class="text-sm mt-1">{{ naturalPixelSize?.naturalWidth }}×{{ naturalPixelSize?.naturalHeight }}</div>
        </div>

        <div class="flex flex-1 items-center justify-center py-4">
            <div :key="key" class="flex flex-wrap gap-4 items-center justify-center">
                <figure v-for="{ height, width } in imageSizes" class="flex flex-col gap-1 flex-shrink-0">
                    <figcaption class="text-center text-xs font-medium text-gray-400">
                        <span v-if="!height">width {{ width }}</span>
                        <span v-else-if="!width">height {{ height }}</span>
                        <span v-else>{{ width }}x{{ height }}</span>
                    </figcaption>
                    <img
                        :src="getResizeImageUrl(originalImage, { height, width })"
                        :srcset="`${getResizeImageUrl(originalImage, { height: height * 2, width: width * 2 })} 2x`"
                        alt=""
                        class="bg-white/5"
                        :style="{
                            height: `${height}px`,
                            width: `${width}px`,
                            'border-radius': `min(calc(${width??height}px / 8), 16px)`,
                            aspectRatio,
                        }"
                    >
                </figure>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import AppSpinner from './app-spinner.vue'

const formats = ['png', 'jpg']
const selectedFormat = ref(formats[0])

const resolutions = ['1080p', '4k']
const selectedResolution = ref(resolutions[0])

const orientations = ['landscape', 'portrait']
const selectedOrientation = ref(orientations[0])

const key = ref(Date.now())
const imageSizes = ref([
    { width: 256 },
    { height: 256 },
    { height: 256, width: 256 },
    { height: 128, width: 128 },
    { height: 64, width: 64 },
    { height: 48, width: 48 },
])

const originalImage = computed(() => {
    const resolution = selectedResolution.value
    const orientation = selectedOrientation.value
    const format = selectedFormat.value
    return getImageUrl({ resolution, orientation, format })
})

function getImageUrl({ resolution, orientation, format }) {
    return `http://localhost/photos/example.${resolution}.${orientation}.${format}`
}

const waiting = ref(true)
const naturalPixelSizeMap = new Map()
const naturalPixelSize = computed(() => naturalPixelSizeMap.get(originalImage.value))
const aspectRatioMap = new Map()
const aspectRatio = computed(() => aspectRatioMap.get(originalImage.value))

cacheImagesAspectRatio().then(() => {
    waiting.value = false
})

watch(originalImage, () => {
    reloadWithoutCache()
})

function calculateAspectRatio(src) {
    return new Promise((resolve, reject) => {
        const image = new Image()
        image.onload = () => {
            const { naturalWidth, naturalHeight } = image
            resolve({ aspectRatio: naturalWidth / naturalHeight, naturalWidth, naturalHeight })
        }
        image.onerror = reject
        image.src = src
    })
}

async function cacheImagesAspectRatio() {
    for (const format of formats) {
        for (const resolution of resolutions) {
            for (const orientation of orientations) {
                try {
                    const url = getImageUrl({ resolution, orientation, format })
                    const { aspectRatio, naturalWidth, naturalHeight } = await calculateAspectRatio(url)
                    aspectRatioMap.set(url, aspectRatio)
                    naturalPixelSizeMap.set(url, { naturalWidth, naturalHeight })
                } catch {
                    // Do nothing.
                }
            }
        }
    }
}

function getResizeImageUrl(originalUrl, params) {
    let { width, height } = params
    let url = new URL(originalUrl)
    let sizeSegment

    if (width && height) {
        sizeSegment = `${width}x${height}`
    } else if (width) {
        sizeSegment = `w${width}`
    } else if (height) {
        sizeSegment = `h${height}`
    }

    if (sizeSegment) {
        url.pathname = `/media/${sizeSegment}${url.pathname}`
    }

    return url.toString() + '?' + Date.now()
}

function reloadWithoutCache() {
    key.value = Date.now()
}
</script>

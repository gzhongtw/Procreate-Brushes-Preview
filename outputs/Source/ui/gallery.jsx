// Adapted from Astryx classic-gallery: shared frame, spacing and responsive media grid.
import React from 'react';
import {renderToStaticMarkup} from 'react-dom/server';
import {Theme} from '@astryxdesign/core/theme';
import {themes,defaultThemeSlug} from '../../../astryx-themes.js';
import {VStack} from '@astryxdesign/core/VStack';
import {HStack} from '@astryxdesign/core/HStack';
import {Grid} from '@astryxdesign/core/Grid';
import {Card} from '@astryxdesign/core/Card';
import {Heading} from '@astryxdesign/core/Heading';
import {Text} from '@astryxdesign/core/Text';
import {Section} from '@astryxdesign/core/Section';
const marker = '__BRUSH_CARDS__';
const frame = renderToStaticMarkup(<Theme theme={themes[defaultThemeSlug]} mode="dark"><main className="gallery"><VStack gap={8} width="100%">
  <header><VStack gap={3}><HStack hAlign="between" vAlign="center" gap={4} wrap="wrap"><Heading level={1}>__SET_NAME__</Heading><Text type="body" color="secondary">__COUNT__ 支筆刷</Text></HStack><Text type="supporting" color="secondary">__HINT__</Text></VStack></header>
  <Grid columns={{minWidth:300,max:3}} gap={4}>{marker}</Grid>
</VStack></main></Theme>);
function card(interactive) {
  const media=<img className="stroke" src="__IMAGE_SRC__" alt="__BRUSH_NAME__ 筆觸" />;
  return renderToStaticMarkup(<Card padding={4} className="brush-card"><VStack gap={4}>
    <HStack hAlign="between" vAlign="center" gap={3}><Heading level={3} accessibilityLevel={2}>__BRUSH_NAME__</Heading><Text type="code" color="secondary">__INDEX__</Text></HStack>
    {interactive?<button type="button" className="stroke-stage" aria-label="放大 __BRUSH_NAME__" data-brush-zoom="true">{media}</button>:<figure className="stroke-stage">{media}</figure>}
  </VStack></Card>);
}
export const templates={frame,card:card(true),staticCard:card(false)};

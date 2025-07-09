import React, {type ReactNode, useRef, useState} from 'react';
import clsx from 'clsx';
import {ThemeClassNames} from '@docusaurus/theme-common';
import {
  useAnnouncementBar,
  useScrollPosition,
  useLocationChange
} from '@docusaurus/theme-common/internal';
import {translate} from '@docusaurus/Translate';
import DocSidebarItems from '@theme/DocSidebarItems';
import type {Props} from '@theme/DocSidebar/Desktop/Content';

import styles from './styles.module.css';

function useShowAnnouncementBar() {
  const {isActive} = useAnnouncementBar();
  const [showAnnouncementBar, setShowAnnouncementBar] = useState(isActive);

  useScrollPosition(
    ({scrollY}) => {
      if (isActive) {
        setShowAnnouncementBar(scrollY === 0);
      }
    },
    [isActive],
  );
  return isActive && showAnnouncementBar;
}

export default function DocSidebarDesktopContent({
  path,
  sidebar,
  className,
}: Props): ReactNode {
  const showAnnouncementBar = useShowAnnouncementBar();
  const [focusedPath, setFocusedPath] = React.useState(null);
  const sidebarRef = useRef<HTMLElement>(null);

  useLocationChange(() => {
    if (focusedPath && focusedPath === path) {
      (sidebarRef.current.querySelector(`a[href="${focusedPath}"]`) as HTMLElement)?.focus();
    }
  })

  const onFocus = (event) => {
    setFocusedPath(event.target.getAttribute('href'));
  }

  const onBlur = () => {
    setFocusedPath(null);
  }

  return (
    <nav
      aria-label={translate({
        id: 'theme.docs.sidebar.navAriaLabel',
        message: 'Docs sidebar',
        description: 'The ARIA label for the sidebar navigation',
      })}
      className={clsx(
        'menu thin-scrollbar',
        styles.menu,
        showAnnouncementBar && styles.menuWithAnnouncementBar,
        className,
      )}
      ref={sidebarRef}
      onFocus={onFocus}
      onBlur={onBlur}>
      <ul className={clsx(ThemeClassNames.docs.docSidebarMenu, 'menu__list')}>
        <DocSidebarItems items={sidebar} activePath={path} level={1}/>
      </ul>
    </nav>
  );
}

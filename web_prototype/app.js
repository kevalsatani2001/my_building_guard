/**
 * ============================================================================
 * MY BUILDING GUARD — 100% ACCURATE FLUTTER APP ARCHITECTURE PROTOTYPE ENGINE
 * Replicates the authentic Flutter codebase:
 * - AdminDashboard: 4-Tab IndexedStack (Home, Security, Finance, Society)
 * - MemberScreen: 4-Tab IndexedStack (Home, Visitors, Bills, Services)
 * - WatchmanScreen: Royal Indigo Header + Segmented Tabs + Patrol
 * - SuperAdminDashboard: Midnight Obsidian + Bento KPI Deck + 4 Tabs
 * - AppNavigationDrawer: 100% mirror of lib/widgets/app_navigation_drawer.dart
 * - Navigator.push / pop Stack with Back Button (❮)
 * - FloatingGlassmorphicNavBar with active indicators & badges
 * - Full Interactive Modals & Web Audio Synthesizer
 * ============================================================================
 */

const PrototypeApp = (() => {
  // Navigation Stack for Flutter Navigator.push & pop
  const navigationStack = [];

  // Application State
  const state = {
    currentRole: 'admin',
    currentAdminTab: 0,
    currentMemberTab: 0,
    currentWatchmanTab: 0,
    currentSuperAdminTab: 0,
    currentVisitorScope: 'my_flat',
    currentStatusFilter: 'all',
    currentLang: 'gu',
    isAudioEnabled: true,
    viewMode: 'mobile',
    maintenancePaid: false,
    pollVoted: false,
    pollVotes: { yes: 33, no: 9 },
    visitors: [
      {
        id: 'v-101',
        name: 'કિશનભાઈ ત્રિવેદી',
        flat: 'A-402',
        purpose: 'ઈન્ટરનેટ વાયર રિપેરિંગ (Airtel)',
        phone: '+91 97123 45678',
        photo: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&auto=format&fit=crop&q=80',
        time: '10:30 AM',
        status: 'approved',
        vehicle: 'GJ-01-BK-9821'
      },
      {
        id: 'v-102',
        name: 'અલ્પેશ પરમાર',
        flat: 'B-201',
        purpose: 'Amazon પાર્સલ ડિલિવરી',
        phone: '+91 98980 11223',
        photo: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&auto=format&fit=crop&q=80',
        time: '10:15 AM',
        status: 'approved',
        vehicle: 'GJ-01-TX-4412'
      },
      {
        id: 'v-103',
        name: 'સુરેશભાઈ મહેતા',
        flat: 'A-402',
        purpose: 'મહેમાન / અંગત મુલાકાત',
        phone: '+91 98250 12345',
        photo: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
        time: '10:42 AM',
        status: 'pending',
        vehicle: 'GJ-01-AB-1234'
      }
    ],
    members: [
      { flat: 'A-101', name: 'હસમુખભાઈ પટેલ', phone: '+91 98240 11111', type: 'Owner' },
      { flat: 'A-102', name: 'પ્રવીણભાઈ શાહ', phone: '+91 98240 22222', type: 'Owner' },
      { flat: 'A-402', name: 'રાજેશભાઈ પટેલ', phone: '+91 98250 12345', type: 'Owner' },
      { flat: 'B-201', name: 'કિરીટભાઈ શાહ', phone: '+91 98980 11223', type: 'Owner' },
      { flat: 'B-301', name: 'અમિતભાઈ શાહ', phone: '+91 98240 55441', type: 'Owner' },
      { flat: 'C-104', name: 'નરેશભાઈ જોશી', phone: '+91 98251 77889', type: 'Tenant' }
    ],
    patrolRoute: [
      { name: '૧. મેઇન ગેટ એન્ટ્રી પોઇન્ટ', time: '10:15 PM', status: 'done', gps: 'GPS Verified' },
      { name: '૨. બેઝમેન્ટ B-2 પાર્કિંગ રડાર', time: '10:22 PM', status: 'done', gps: 'GPS Verified' },
      { name: '૩. વિંગ A લિફ્ટ લોબી & ટેરેસ', time: '10:35 PM', status: 'done', gps: 'GPS Verified' },
      { name: '૪. સોસાયટી બેક ગેટ ફેન્સિંગ', time: '10:48 PM', status: 'pending', gps: 'Scheduled' }
    ],
    societies: [
      { name: 'શ્રી શ્યામ રેસીડેન્સી', city: 'અમદાવાદ', units: 50, arch: 'Wing', admin: 'હરેશભાઈ પટેલ', status: 'Active' },
      { name: 'ગોકુલધામ સોસાયટી', city: 'સુરત', units: 120, arch: 'Street', admin: 'ચંપકભાઈ ગડા', status: 'Active' },
      { name: 'શિવ શક્તિ એન્ક્લેવ', city: 'રાજકોટ', units: 36, arch: 'Wing', admin: 'દિનેશ સોલંકી', status: 'Pending Appeal' },
      { name: 'સિગ્નેચર બિઝનેસ પાર્ક', city: 'વડોદરા', units: 80, arch: 'Commercial', admin: 'રાજેશ જોશી', status: 'Active' }
    ],
    currentVisitorPhoto: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
    visitorPhotos: [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=400&auto=format&fit=crop&q=80'
    ],
    photoIndex: 0
  };

  // Role Configurations (Scaffold, AppBar & Drawer)
  const roleConfigs = {
    admin: {
      rootScreenId: 'screen-admin-dashboard',
      appBarTitle: 'સોસાયટી મેનેજર',
      appBarSubtitle: 'શ્રી શ્યામ રેસીડેન્સી • કમિટી ડેસ્ક',
      brandIcon: '🏛️',
      actionIcon: '📊',
      actionLabel: 'રિપોર્ટ',
      isDark: false,
      userName: 'હરેશભાઈ પટેલ',
      societyName: 'શ્રી શ્યામ રેસીડેન્સી',
      unitNumber: '',
      roleBadge: 'સોસાયટી એડમિન',
      avatar: 'H',
      gradient: 'linear-gradient(135deg, #1E1B4B 0%, #4338CA 50%, #3B82F6 100%)'
    },
    member: {
      rootScreenId: 'screen-member-home',
      appBarTitle: 'માય સોસાયટી',
      appBarSubtitle: 'A-402 • સભ્ય પોર્ટલ',
      brandIcon: '🏢',
      actionIcon: '🚨',
      actionLabel: 'SOS',
      isDark: false,
      userName: 'રાજેશભાઈ પટેલ',
      societyName: 'શ્રી શ્યામ રેસીડેન્સી',
      unitNumber: 'A-402',
      roleBadge: 'સોસાયટી સભ્ય (Member)',
      avatar: 'R',
      gradient: 'linear-gradient(135deg, #0C4A6E 0%, #0284C7 50%, #38BDF8 100%)'
    },
    watchman: {
      rootScreenId: 'screen-watchman-gate',
      appBarTitle: 'ગેટ કન્ટ્રોલ',
      appBarSubtitle: 'ગેટ ૧ • રમણભાઈ (ઓન ડ્યુટી)',
      brandIcon: '🛡️',
      actionIcon: '🚨',
      actionLabel: 'સાયરન',
      isDark: false,
      userName: 'રમણભાઈ પરમાર',
      societyName: 'ગેટ નં. ૧ સિક્યુરિટી',
      unitNumber: 'Gate 1',
      roleBadge: 'સિક્યુરિટી ગાર્ડ (Watchman)',
      avatar: 'G',
      gradient: 'linear-gradient(135deg, #064E3B 0%, #0D9488 50%, #10B981 100%)'
    },
    super_admin: {
      rootScreenId: 'screen-superadmin-dashboard',
      appBarTitle: 'SUPER ADMIN',
      appBarSubtitle: 'LIVE ENGINE • કમાન્ડ સેન્ટર',
      brandIcon: '👑',
      actionIcon: '🛡️',
      actionLabel: 'લૉગ્સ',
      isDark: true,
      userName: 'કેવલ સાતાણી',
      societyName: 'કંટ્રોલ હેડક્વાર્ટર (HQ)',
      unitNumber: 'Root',
      roleBadge: 'સિસ્ટમ સુપર એડમિન',
      avatar: 'S',
      gradient: 'linear-gradient(135deg, #3B0764 0%, #7C3AED 50%, #A855F7 100%)'
    }
  };

  // Web Audio Synthesizer
  const audioCtx = window.AudioContext || window.webkitAudioContext ? new (window.AudioContext || window.webkitAudioContext)() : null;

  function playTone(freq, type, duration, delay = 0) {
    if (!state.isAudioEnabled || !audioCtx) return;
    try {
      if (audioCtx.state === 'suspended') audioCtx.resume();
      setTimeout(() => {
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.type = type;
        osc.frequency.setValueAtTime(freq, audioCtx.currentTime);
        gain.gain.setValueAtTime(0.15, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + duration);
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start();
        osc.stop(audioCtx.currentTime + duration);
      }, delay);
    } catch (e) {
      console.warn('Audio play error:', e);
    }
  }

  function playChime() {
    playTone(659.25, 'sine', 0.4, 0);   // E5
    playTone(523.25, 'sine', 0.6, 220); // C5
  }

  function playSuccess() {
    playTone(523.25, 'triangle', 0.15, 0);
    playTone(659.25, 'triangle', 0.15, 120);
    playTone(783.99, 'triangle', 0.35, 240);
  }

  function playAlertSound() {
    playTone(880, 'sawtooth', 0.2, 0);
    playTone(660, 'sawtooth', 0.25, 180);
  }

  // ==========================================================================
  // NAVIGATION STACK (Navigator.push & Navigator.pop)
  // ==========================================================================
  function getActiveScreen() {
    return document.querySelector('.flutter-screen.active');
  }

  function getCurrentScreenInfo() {
    const active = getActiveScreen();
    const titleEl = document.getElementById('appBarTitle');
    const subEl = document.getElementById('appBarSubtitle');
    return {
      id: active ? active.id : roleConfigs[state.currentRole].rootScreenId,
      title: titleEl ? titleEl.innerText : '',
      subtitle: subEl ? subEl.innerText : ''
    };
  }

  function pushScreen(screenId, title, subtitle) {
    closeDrawer();
    const targetId = screenId.startsWith('screen-') ? screenId : `screen-${screenId}`;
    const targetScreen = document.getElementById(targetId);
    if (!targetScreen) {
      console.warn(`Screen ${targetId} not found!`);
      showToast(`સ્ક્રીન ${screenId} મળી નથી`, 'info');
      return;
    }

    const currentScreen = getActiveScreen();
    if (currentScreen) {
      navigationStack.push(getCurrentScreenInfo());
      currentScreen.classList.remove('active');
    }

    targetScreen.classList.add('active');

    // Update AppBar
    const titleEl = document.getElementById('appBarTitle');
    const subEl = document.getElementById('appBarSubtitle');
    if (titleEl && title) titleEl.innerText = title;
    if (subEl) subEl.innerText = subtitle || (roleConfigs[state.currentRole].societyName);

    // Show Back Button, Hide Drawer Hamburger
    const btnDrawer = document.getElementById('btnDrawerHamburger');
    const btnBack = document.getElementById('btnAppBack');
    if (btnDrawer) btnDrawer.style.display = 'none';
    if (btnBack) btnBack.style.display = 'flex';

    const viewport = document.getElementById('flutterViewport');
    if (viewport) viewport.scrollTop = 0;
  }

  function popNavigation() {
    if (navigationStack.length === 0) return;

    const currentScreen = getActiveScreen();
    if (currentScreen) currentScreen.classList.remove('active');

    const prev = navigationStack.pop();
    const prevScreen = document.getElementById(prev.id);
    if (prevScreen) prevScreen.classList.add('active');

    // Restore Title & Subtitle
    const titleEl = document.getElementById('appBarTitle');
    const subEl = document.getElementById('appBarSubtitle');
    if (titleEl) titleEl.innerText = prev.title;
    if (subEl) subEl.innerText = prev.subtitle;

    // Restore Hamburger if back at root
    if (navigationStack.length === 0) {
      const btnDrawer = document.getElementById('btnDrawerHamburger');
      const btnBack = document.getElementById('btnAppBack');
      if (btnDrawer) btnDrawer.style.display = 'flex';
      if (btnBack) btnBack.style.display = 'none';
    }

    const viewport = document.getElementById('flutterViewport');
    if (viewport) viewport.scrollTop = 0;
  }

  function openDrawer() {
    const drawer = document.getElementById('appNavigationDrawer');
    const scrim = document.getElementById('drawerScrim');
    if (drawer) drawer.classList.add('open');
    if (scrim) scrim.classList.add('active');
  }

  function closeDrawer() {
    const drawer = document.getElementById('appNavigationDrawer');
    const scrim = document.getElementById('drawerScrim');
    if (drawer) drawer.classList.remove('open');
    if (scrim) scrim.classList.remove('active');
  }

  // ==========================================================================
  // ROLE SWITCHING (Admin, Member, Watchman, Super Admin)
  // ==========================================================================
  function switchRole(roleKey) {
    if (!roleConfigs[roleKey]) return;
    state.currentRole = roleKey;
    navigationStack.length = 0; // Clear stack

    const config = roleConfigs[roleKey];

    // 1. Update Top Bar Tabs
    document.querySelectorAll('.role-tab').forEach(tab => {
      tab.classList.toggle('active', tab.getAttribute('data-role') === roleKey);
    });

    // 2. Update Theme & Persona Backlight
    const body = document.body;
    const scaffold = document.getElementById('flutterScaffold');
    body.setAttribute('data-active-role', roleKey);
    playTone(roleKey === 'admin' ? 523.25 : (roleKey === 'member' ? 659.25 : (roleKey === 'watchman' ? 440 : 783.99)), 'sine', 0.12, 0.05);

    if (config.isDark) {
      body.classList.remove('theme-light');
      body.classList.add('theme-dark');
      if (scaffold) scaffold.classList.add('dark-theme');
    } else {
      body.classList.remove('theme-dark');
      body.classList.add('theme-light');
      if (scaffold) scaffold.classList.remove('dark-theme');
    }

    // 3. Reset Leading Icon
    const btnDrawer = document.getElementById('btnDrawerHamburger');
    const btnBack = document.getElementById('btnAppBack');
    if (btnDrawer) btnDrawer.style.display = 'flex';
    if (btnBack) btnBack.style.display = 'none';

    // 4. Update AppBar
    const titleEl = document.getElementById('appBarTitle');
    const subEl = document.getElementById('appBarSubtitle');
    const brandIconEl = document.getElementById('appBarBrandIcon');
    const actionIconEl = document.getElementById('appBarActionIcon');
    const actionLabelEl = document.getElementById('appBarActionLabel');
    const subTagEl = document.getElementById('appBarSubTag');

    if (titleEl) titleEl.innerText = config.appBarTitle;
    if (subEl) subEl.innerText = config.appBarSubtitle;
    if (brandIconEl) brandIconEl.innerText = config.brandIcon;
    if (actionIconEl) actionIconEl.innerText = config.actionIcon;
    if (actionLabelEl) actionLabelEl.innerText = config.actionLabel;

    if (subTagEl) {
      if (roleKey === 'member') {
        subTagEl.innerText = 'A-402';
        subTagEl.style.display = 'inline-block';
      } else {
        subTagEl.style.display = 'none';
      }
    }

    // 5. Hide watchman header if not watchman
    const appBar = document.getElementById('flutterAppBar');
    if (roleKey === 'watchman') {
      if (appBar) appBar.style.display = 'none'; // Watchman has its own royal header!
    } else {
      if (appBar) appBar.style.display = 'flex';
    }

    // 6. Deactivate All Screens, Activate Role Screen
    document.querySelectorAll('.flutter-screen').forEach(scr => scr.classList.remove('active'));
    const rootScreen = document.getElementById(config.rootScreenId);
    if (rootScreen) rootScreen.classList.add('active');

    // 7. Update Bottom Nav Bar per role
    const floatingNav = document.getElementById('floatingGlassNav');
    const adminNav = document.getElementById('adminNavItems');
    const memberNav = document.getElementById('memberNavItems');
    const watchmanNav = document.getElementById('watchmanNavItems');
    const saNav = document.getElementById('superAdminNavItems');

    if (floatingNav) floatingNav.style.display = 'flex';

    if (adminNav) adminNav.style.display = roleKey === 'admin' ? 'flex' : 'none';
    if (memberNav) memberNav.style.display = roleKey === 'member' ? 'flex' : 'none';
    if (watchmanNav) watchmanNav.style.display = roleKey === 'watchman' ? 'flex' : 'none';
    if (saNav) saNav.style.display = roleKey === 'super_admin' ? 'flex' : 'none';

    // 8. Reset active tab for the role
    if (roleKey === 'admin') switchAdminTab(0);
    else if (roleKey === 'member') switchMemberTab(0);
    else if (roleKey === 'watchman') switchWatchmanBottomTab(0);
    else if (roleKey === 'super_admin') switchSuperAdminTab(0);

    // 9. Update Drawer
    updateDrawerHeader(config);
    populateDrawerRoleItems(roleKey);

    const viewport = document.getElementById('flutterViewport');
    if (viewport) viewport.scrollTop = 0;
  }

  // ==========================================================================
  // TAB CONTROLLERS FOR ALL 4 ROLES
  // ==========================================================================

  // 1. ADMIN TABS (0: Home, 1: Security, 2: Finance, 3: Society)
  function switchAdminTab(index) {
    state.currentAdminTab = index;
    const tabIds = ['admin-tab-home', 'admin-tab-security', 'admin-tab-finance', 'admin-tab-society'];
    tabIds.forEach((id, i) => {
      const el = document.getElementById(id);
      if (el) el.classList.toggle('active', i === index);
    });

    const adminNav = document.getElementById('adminNavItems');
    if (adminNav) {
      adminNav.querySelectorAll('.nav-item-btn').forEach((btn, i) => {
        btn.classList.toggle('active', i === index);
      });
    }
  }

  // 2. MEMBER TABS (0: Home, 1: Visitors, 2: Bills, 3: Services)
  function switchMemberTab(index) {
    state.currentMemberTab = index;
    const tabIds = ['member-tab-home', 'member-tab-visitors', 'member-tab-bills', 'member-tab-services'];
    tabIds.forEach((id, i) => {
      const el = document.getElementById(id);
      if (el) el.classList.toggle('active', i === index);
    });

    const memberNav = document.getElementById('memberNavItems');
    if (memberNav) {
      memberNav.querySelectorAll('.nav-item-btn').forEach((btn, i) => {
        btn.classList.toggle('active', i === index);
      });
    }
  }

  // 3. WATCHMAN TABS (0: Entry, 1: Logs)
  function switchWatchmanTab(index) {
    state.currentWatchmanTab = index;
    const entryEl = document.getElementById('watchman-tab-entry');
    const logsEl = document.getElementById('watchman-tab-history');
    if (entryEl) entryEl.classList.toggle('active', index === 0);
    if (logsEl) logsEl.classList.toggle('active', index === 1);

    const btnEntry = document.getElementById('btnWSegEntry');
    const btnLogs = document.getElementById('btnWSegLogs');
    if (btnEntry) btnEntry.classList.toggle('active', index === 0);
    if (btnLogs) btnLogs.classList.toggle('active', index === 1);

    const watchmanNav = document.getElementById('watchmanNavItems');
    if (watchmanNav) {
      watchmanNav.querySelectorAll('.nav-item-btn').forEach((btn, i) => {
        btn.classList.toggle('active', i === index);
      });
    }
  }

  function switchWatchmanBottomTab(index) {
    if (index === 0) {
      switchWatchmanTab(0);
    } else if (index === 1) {
      switchWatchmanTab(1);
    } else if (index === 2) {
      pushScreen('watchman-patrol', 'રાત્રિ QR પેટ્રોલિંગ');
    }
  }

  // 4. SUPER ADMIN TABS (0: Societies, 1: Users, 2: Audit, 3: Operations)
  function switchSuperAdminTab(index) {
    state.currentSuperAdminTab = index;
    const tabIds = ['sa-tab-societies', 'sa-tab-users', 'sa-tab-audit', 'sa-tab-operations'];
    tabIds.forEach((id, i) => {
      const el = document.getElementById(id);
      if (el) el.classList.toggle('active', i === index);
    });

    const saNav = document.getElementById('superAdminNavItems');
    if (saNav) {
      saNav.querySelectorAll('.nav-item-btn').forEach((btn, i) => {
        btn.classList.toggle('active', i === index);
      });
    }

    for (let i = 0; i < 4; i++) {
      const tabBtn = document.getElementById(`saTab${i}`);
      if (tabBtn) tabBtn.classList.toggle('active', i === index);
    }
  }

  // Member Visitor Scope Switcher
  function switchVisitorScope(scope) {
    state.currentVisitorScope = scope;
    const btnMy = document.getElementById('btnScopeMyFlat');
    const btnAll = document.getElementById('btnScopeAllSoc');
    if (btnMy) btnMy.classList.toggle('active', scope === 'my_flat');
    if (btnAll) btnAll.classList.toggle('active', scope === 'all_society');
    renderMemberVisitors();
  }

  // Member Visitor Status Filter
  function filterVisitorsByStatus(status) {
    state.currentStatusFilter = status;
    document.querySelectorAll('.visitor-status-filters .status-tab').forEach(tab => {
      tab.classList.remove('active');
    });
    if (event && event.target) event.target.classList.add('active');
    renderMemberVisitors();
  }

  // ==========================================================================
  // DRAWER MANAGEMENT (app_navigation_drawer.dart)
  // ==========================================================================
  function updateDrawerHeader(config) {
    const avatarEl = document.getElementById('drawerAvatar');
    const userNameEl = document.getElementById('drawerUserName');
    const socNameEl = document.getElementById('drawerSocName');
    const unitBadgeEl = document.getElementById('drawerUnitBadge');
    const rolePillEl = document.getElementById('drawerRolePill');
    const headerGradientEl = document.getElementById('drawerHeaderGradient');

    if (avatarEl) avatarEl.innerText = config.avatar;
    if (userNameEl) userNameEl.innerText = config.userName;
    if (socNameEl) socNameEl.innerText = config.societyName;
    if (unitBadgeEl) {
      if (config.unitNumber) {
        unitBadgeEl.innerText = config.unitNumber;
        unitBadgeEl.style.display = 'inline-block';
      } else {
        unitBadgeEl.style.display = 'none';
      }
    }
    if (rolePillEl) rolePillEl.innerText = config.roleBadge;
    if (headerGradientEl) headerGradientEl.style.background = config.gradient;
  }

  function populateDrawerRoleItems(roleKey) {
    const container = document.getElementById('drawerRoleItemsContainer');
    const label = document.getElementById('drawerRoleShortcutsLabel');
    if (!container) return;

    container.innerHTML = '';
    const labelMap = {
      admin: 'એડમિન શોર્ટકટ્સ',
      member: 'મારા શોર્ટકટ્સ',
      watchman: 'સિક્યુરિટી શોર્ટકટ્સ',
      super_admin: 'સુપર એડમિન કંટ્રોલ'
    };
    if (label) label.innerText = labelMap[roleKey] || 'શોર્ટકટ્સ';

    let items = [];

    if (roleKey === 'admin') {
      items = [
        { icon: '🏦', title: 'સોસાયટી બેંક & UPI સેટિંગ્સ', sub: '૦% ફી ડાયરેક્ટ બેંક એકાઉન્ટ', color: '#4338CA', action: () => pushScreen('admin-bank-settings', 'બેંક & UPI સેટિંગ્સ') },
        { icon: '👥', title: 'સભ્યો & સ્ટાફ ડિરેક્ટરી', sub: '૫૦ ફ્લેટ્સ • માલિક / ભાડુઆત', color: '#0284C7', action: () => pushScreen('admin-members-directory', 'સભ્યો ડિરેક્ટરી') },
        { icon: '🧾', title: 'મેન્ટેનન્સ મેનેજમેન્ટ & રસીદો', sub: 'બલ્ક બિલ & ઓટો રસીદ', color: '#0D9488', action: () => pushScreen('admin-maintenance', 'મેન્ટેનન્સ કલેક્શન') },
        { icon: '⚠️', title: 'ફરિયાદ નિવારણ ડેસ્ક', sub: 'રહીશોની ફરિયાદો & સ્ટેટસ', color: '#EA580C', action: () => pushScreen('admin-complaints', 'ફરિયાદ નિવારણ ડેસ્ક') },
        { icon: '📢', title: 'ડિજિટલ નોટિસ બોર્ડ', sub: 'WhatsApp & પુશ પરિપત્ર', color: '#8B5CF6', action: () => pushScreen('admin-broadcast', 'નોટિસ બોર્ડ & પરિપત્રો') },
        { icon: '💼', title: 'સોસાયટી એકાઉન્ટ્સ & ઓડિટ', sub: 'આવક, ખર્ચ & સત્તાવાર PDF', color: '#059669', action: () => pushScreen('admin-accounts', 'સોસાયટી હિસાબ & ઓડિટ') },
        { icon: '🗳️', title: 'પોલ્સ & લોકશાહી મતદાન', sub: 'સભ્યોના મત & નિર્ણયો', color: '#D97706', action: () => pushScreen('admin-polls', 'સોસાયટી પોલ્સ & વોટિંગ') },
        { icon: '🛡️', title: 'ગાર્ડ QR પેટ્રોલિંગ કંટ્રોલ', sub: 'ચોકીદાર રાત્રિ પેટ્રોલિંગ લોગ્સ', color: '#4F46E5', action: () => pushScreen('admin-patrol', 'ગાર્ડ QR પેટ્રોલિંગ') },
        { icon: '✍️', title: 'AGM સહી શીટ જનરેટર', sub: 'વાર્ષિક સાધારણ સભા સહી પત્રક', color: '#0D9488', action: () => pushScreen('admin-agm', 'AGM સહી શીટ') }
      ];
    } else if (roleKey === 'member') {
      items = [
        { icon: '🚗', title: 'મારા વાહનો & પાર્કિંગ સ્લોટ', sub: 'રજીસ્ટર્ડ વાહનો & રોંગ પાર્કિંગ', color: '#0284C7', action: () => pushScreen('member-vehicles', 'મારા વાહનો & પાર્કિંગ') },
        { icon: '🎟️', title: 'પ્રિ-અપ્રૂવ્ડ વિઝિટર્સ (QR પાસ)', sub: 'મહેમાન અથવા ડિલિવરી પાસ બનાવો', color: '#0D9488', action: () => pushScreen('member-pre-approve', 'પ્રિ-અપ્રૂવ્ડ વિઝિટર્સ') },
        { icon: '👤', title: 'ડેઇલી સ્ટાફ & હેલ્પર્સ', sub: 'ઘરકામવાળા બાઈ, ડ્રાઈવર, કૂક', color: '#7C3AED', action: () => pushScreen('member-daily-staff', 'ડેઇલી સ્ટાફ & હેલ્પર્સ') },
        { icon: '📝', title: 'ફરિયાદ નોંધાવો (Complaints)', sub: 'સોસાયટી કમિટીને ફરિયાદ મોકલો', color: '#DC2626', action: () => pushScreen('member-complaints', 'ફરિયાદ નિવારણ ડેસ્ક') },
        { icon: '💼', title: 'સોસાયટી એકાઉન્ટ સ્ટેટમેન્ટ', sub: 'સોસાયટીના ખર્ચ અને ફંડ વિગતો', color: '#059669', action: () => pushScreen('member-accounts', 'સોસાયટી હિસાબ વિગત') },
        { icon: '🎉', title: 'ક્લબહાઉસ & એમેનિટીઝ સ્લોટ', sub: 'પાર્ટી હોલ & ગેસ્ટ પાર્કિંગ બુકિંગ', color: '#F59E0B', action: () => pushScreen('member-amenities', 'એમેનિટીઝ & હોલ બુકિંગ') },
        { icon: '📜', title: 'મુલાકાતી હિસ્ટ્રી (Visitor Log)', sub: 'તમારા ઘરે આવેલા તમામ મુલાકાતીઓ', color: '#4338CA', action: () => pushScreen('member-visitors', 'મુલાકાતી હિસ્ટ્રી') }
      ];
    } else if (roleKey === 'watchman') {
      items = [
        { icon: '🚪', title: 'લાઈવ ગેટ એન્ટ્રી કન્સોલ', sub: 'કેમેરા ફોટો & ફ્લેટ રિંગ સિસ્ટમ', color: '#0D9488', action: () => { closeDrawer(); switchWatchmanTab(0); } },
        { icon: '📱', title: 'QR ગેટ પાસ સ્કેનર', sub: 'સભ્યએ મોકલેલ મહેમાન પાસ સ્કેન', color: '#38BDF8', action: () => { closeDrawer(); openModal('modalScanQrPass'); } },
        { icon: '🚗', title: 'વાહન નંબર સર્ચ (Parking Radar)', sub: 'ગાડી નંબરથી ફ્લેટ માલિકની શોધ', color: '#F59E0B', action: () => { closeDrawer(); openModal('modalVehicleLookup'); } },
        { icon: '🚶‍♂️', title: 'રાત્રિ QR પેટ્રોલિંગ (Patrol)', sub: 'કેમ્પસ ચેકપોઇન્ટ વેરિફિકેશન', color: '#10B981', action: () => pushScreen('watchman-patrol', 'રાત્રિ QR પેટ્રોલિંગ') }
      ];
    } else if (roleKey === 'super_admin') {
      items = [
        { icon: '🏢', title: 'તમામ સોસાયટી ડિરેક્ટરી', sub: 'રજિસ્ટર્ડ સોસાયટીઓ તપાસો', color: '#F59E0B', action: () => { closeDrawer(); switchSuperAdminTab(0); } },
        { icon: '🚀', title: 'નવી સોસાયટી ઓનબોર્ડ કરો', sub: 'ઇન્સ્ટન્ટ સોસાયટી પ્રોવિઝનિંગ', color: '#10B981', action: () => pushScreen('sa-onboard', 'નવી સોસાયટી ઓનબોર્ડ કરો') },
        { icon: '🛡️', title: 'પ્લેટફોર્મ સિક્યુરિટી & ઓડિટ લોગ', sub: 'Single-Device સેશન સિક્યુરિટી', color: '#6366F1', action: () => { closeDrawer(); switchSuperAdminTab(3); } }
      ];
    }

    items.forEach(item => {
      const tile = document.createElement('div');
      tile.className = 'drawer-tile';
      tile.innerHTML = `
        <span class="drawer-tile-icon" style="background:${item.color}18; color:${item.color}; border: 1px solid ${item.color}40;">
          ${item.icon}
        </span>
        <div class="drawer-tile-text">
          <strong>${item.title}</strong>
          <span>${item.sub}</span>
        </div>
        <span class="drawer-chevron">❯</span>
      `;
      tile.addEventListener('click', () => {
        closeDrawer();
        item.action();
      });
      container.appendChild(tile);
    });
  }

  function drawerAction(actionKey) {
    closeDrawer();
    if (actionKey === 'profile') {
      const cfg = roleConfigs[state.currentRole];
      showToast(`પ્રોફાઇલ: ${cfg.userName} (${cfg.roleBadge})`, 'info');
    } else if (actionKey === 'language') {
      applyLanguage(state.currentLang === 'gu' ? 'en' : 'gu');
    } else if (actionKey === 'emergency') {
      showToast('🚨 ઇમરજન્સી: પોલીસ ૧૦૦ • ફાયર ૧૦૧ • એમ્બ્યુલન્સ ૧૦૮ • લિફ્ટ: 9825000000', 'warning');
    } else if (actionKey === 'security') {
      showToast('🛡️ Single-Device Session Guard સક્રિય છે. નવું લોગિન જૂના ડિવાઇસને ઓટો લોગઆઉટ કરશે.', 'success');
    }
  }

  function triggerAppBarAction() {
    if (state.currentRole === 'member') {
      showMemberEmergencyDialog();
    } else if (state.currentRole === 'admin') {
      showAccountsPdfModal();
    } else if (state.currentRole === 'watchman') {
      sendWatchmanSOS();
    } else {
      showToast('🛡️ સુપર એડમિન સિસ્ટમ હેલ્થ: 100% OK', 'success');
    }
  }

  // ==========================================================================
  // MODALS & DIALOGS
  // ==========================================================================
  function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.add('active');
  }

  function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.remove('active');
  }

  // 1. VISITOR INCOMING ALERT FLOW
  function triggerVisitorAlert() {
    const name = document.getElementById('watchmanVisitorName')?.value || 'સુરેશભાઈ મહેતા';
    const flat = document.getElementById('watchmanTargetFlat')?.value || 'A-402';
    const purpose = document.getElementById('watchmanVisitorPurpose')?.value || 'મહેમાન / અંગત મુલાકાત';
    const phone = document.getElementById('watchmanVisitorPhone')?.value || '+91 98250 12345';

    const nameEl = document.getElementById('alertVisitorName');
    const purposeEl = document.getElementById('alertVisitorPurpose');
    const phoneEl = document.getElementById('alertVisitorPhone');
    const photoEl = document.getElementById('alertVisitorPhoto');

    if (nameEl) nameEl.innerText = name;
    if (purposeEl) purposeEl.innerText = `હેતુ: ${purpose}`;
    if (phoneEl) phoneEl.innerText = `ફોન: ${phone}`;
    if (photoEl) photoEl.src = state.currentVisitorPhoto;

    playChime();
    switchRole('member');
    switchMemberTab(1); // Switch to Visitors tab
    openModal('modalVisitorAlert');
    showToast(`🔔 ફ્લેટ ${flat} ના ફોનમાં રીંગ વાગી રહી છે!`, 'warning');
  }

  function respondToVisitor(approved) {
    closeModal('modalVisitorAlert');
    if (approved) {
      playSuccess();
      showToast('✓ વિઝિટર મંજૂર કર્યો! ગેટ ૧ પર લીલો સિગ્નલ મોકલાયો.', 'success');
      state.visitors.unshift({
        id: `v-${Date.now()}`,
        name: document.getElementById('alertVisitorName')?.innerText || 'સુરેશભાઈ મહેતા',
        flat: 'A-402',
        purpose: 'મંજૂર થયેલ મુલાકાતી',
        phone: '+91 98250 12345',
        photo: state.currentVisitorPhoto,
        time: 'હમણાં જ (Just Now)',
        status: 'approved',
        vehicle: 'GJ-01-AB-1234'
      });
      renderMemberVisitors();
      renderWatchmanLogs();
    } else {
      showToast('❌ વિઝિટર અસ્વીકાર કર્યો. ગેટ પર નોટિફિકેશન મોકલાયું.', 'danger');
    }
  }

  function quickTagVisitor(name, purpose) {
    const nameInput = document.getElementById('watchmanVisitorName');
    const purpInput = document.getElementById('watchmanVisitorPurpose');
    if (nameInput) nameInput.value = name;
    if (purpInput) purpInput.value = purpose;
    showToast(`ક્વિક ટૅગ લાગુ: ${name}`, 'info');
  }

  function shuffleVisitorPhoto() {
    state.photoIndex = (state.photoIndex + 1) % state.visitorPhotos.length;
    state.currentVisitorPhoto = state.visitorPhotos[state.photoIndex];
    const imgEl = document.getElementById('watchmanLivePhoto');
    if (imgEl) imgEl.src = state.currentVisitorPhoto;
    showToast('કેમેરા ફોટો અપડેટ થયો', 'info');
  }

  // 2. 0% FEE UPI PAYMENT FLOW
  function openUpiPaymentModal() {
    openModal('modalUpiPayment');
  }

  function simulateUpiAppPay(appName) {
    const randomUtr = Math.floor(100000000000 + Math.random() * 900000000000).toString();
    const utrInput = document.getElementById('manualUtrInput');
    if (utrInput) utrInput.value = randomUtr;
    showToast(`${appName} એપ ઓપન થઈ... સોસાયટી બેંકમાં પેમેન્ટ ટ્રાન્સફર`, 'info');
  }

  function confirmUpiPayment() {
    const utr = document.getElementById('manualUtrInput')?.value || '628109348124';
    state.maintenancePaid = true;
    closeModal('modalUpiPayment');
    playSuccess();

    const payBtn = document.getElementById('btnMemPayUpi');
    const receiptBtn = document.getElementById('btnMemViewReceipt');
    if (payBtn) payBtn.style.display = 'none';
    if (receiptBtn) receiptBtn.style.display = 'inline-flex';

    showToast(`✓ ₹ ૨,૫૦૦ સોસાયટી એકાઉન્ટમાં જમા થયા! UTR: ${utr}`, 'success');
    setTimeout(() => showReceiptModal(utr), 600);
  }

  function showReceiptModal(utr) {
    const utrText = document.getElementById('receiptUtrText');
    if (utrText && utr) utrText.innerText = utr;
    openModal('modalPdfReceipt');
  }

  function showAccountsPdfModal() {
    openModal('modalPdfReceipt');
  }

  // 3. VOTING POLLS
  function castVote(choice) {
    if (state.pollVoted) {
      showToast('તમે આ પોલ પર પહેલેથી જ મત આપી દીધો છે!', 'info');
      return;
    }
    state.pollVoted = true;
    if (choice === 'yes') state.pollVotes.yes++;
    else state.pollVotes.no++;

    playSuccess();
    showToast('✓ તમારો કિંમતી મત સુરક્ષિત નોંધાયો!', 'success');
  }

  // 4. PARKING & WRONG PARKING NOTIFICATION
  function sendWrongParkingNotification() {
    playAlertSound();
    closeModal('modalVehicleLookup');
    showToast('🚨 ફ્લેટ B-301 ને "ખોટું પાર્કિંગ હટાવવા" તાત્કાલિક પુશ એલર્ટ મોકલાયો!', 'danger');
  }

  // 5. QR PASS SCANNER
  function simulateValidQrScan() {
    closeModal('modalScanQrPass');
    playSuccess();
    showToast('✓ ગેટ પાસ માન્ય છે! વિનોદભાઈ જોશી (A-402) - ગેટ એન્ટ્રી લોગ થઈ.', 'success');
  }

  // 6. PRE-APPROVE PASS
  function generatePreApprovePass() {
    const guestName = document.getElementById('preApproveGuestName')?.value || 'વિનોદભાઈ જોશી';
    const card = document.getElementById('preApproveCardResult');
    const disp = document.getElementById('passGuestDisp');
    if (disp) disp.innerText = guestName;
    if (card) card.style.display = 'block';
    playSuccess();
    showToast(`🎟️ ${guestName} માટે ડિજિટલ ગેટ પાસ જનરેટ થયો!`, 'success');
  }

  // 7. COMPLAINTS & NOTICES
  function submitComplaint() {
    closeModal('modalNewComplaint');
    playSuccess();
    showToast('📩 ફરિયાદ સબમિટ થઈ! કમિટી સેક્રેટરીને તાત્કાલિક નોટિફિકેશન ગયું.', 'success');
  }

  function resolveComplaint(btn) {
    if (btn) {
      btn.innerText = '✓ ઉકેલાઈ ગઈ (Resolved)';
      btn.classList.remove('btn-xs-emerald');
      btn.classList.add('btn-xs-outline');
      btn.disabled = true;
    }
    playSuccess();
    showToast('✓ ફરિયાદ ઉકેલાયેલ માર્ક કરાઈ!', 'success');
  }

  function submitNewMember() {
    const name = document.getElementById('addMemName')?.value || 'નવો સભ્ય';
    const flat = document.getElementById('addMemFlat')?.value || 'A-501';
    state.members.push({ flat, name, phone: '+91 98250 99999', type: 'Owner' });
    closeModal('modalAddMember');
    renderRecentMembers();
    playSuccess();
    showToast(`✓ સભ્ય ${name} (${flat}) સફળતાપૂર્વક ઉમેરાયા!`, 'success');
  }

  function submitPublishNotice() {
    closeModal('modalPublishNotice');
    playSuccess();
    showToast('📢 નવો પરિપત્ર તમામ ૫૦ સભ્યોને WhatsApp અને એપ્લિકેશન પુશ નોટિફિકેશન દ્વારા મોકલાયો!', 'success');
  }

  function submitNewPoll() {
    closeModal('modalCreatePoll');
    playSuccess();
    showToast('🚀 નવો મતદાન પોલ તમામ સભ્યો માટે લાઈવ થયો!', 'success');
  }

  function triggerBulkBillAlert() {
    playSuccess();
    showToast('⚡ તમામ ૫૦ ફ્લેટ્સને મેન્ટેનન્સ બિલ WhatsApp PDF અને SMS સાથે મોકલાયા!', 'success');
  }

  function approvePendingUtr(flat) {
    playSuccess();
    showToast(`✓ ફ્લેટ ${flat} નું ₹ ૨,૫૦૦ પેમેન્ટ કન્ફર્મ થયું & રસીદ જનરેટ થઈ!`, 'success');
  }

  function onboardNewSocietySubmit() {
    const name = document.getElementById('saNewSocName')?.value || 'નવી સોસાયટી';
    playSuccess();
    showToast(`🚀 '${name}' સોસાયટી ઇન્સ્ટન્ટ પ્રોવિઝન થઈ! એડમિન લોગિન જનરેટ થયું.`, 'success');
  }

  function sendGlobalBroadcast() {
    playSuccess();
    showToast('📢 તમામ સોસાયટીઓના તમામ ૧,૨૫૦ સભ્યોને સિસ્ટમ અપડેટ એલર્ટ મોકલાયું!', 'warning');
  }

  function simulatePatrolScan(checkpoint) {
    playSuccess();
    showToast(`📍 ચેકપોઇન્ટ વેરિફાઇડ: ${checkpoint} (GPS + Time Locked)`, 'success');
  }

  function openNoticeModal() {
    openModal('modalNoticeDetail');
  }

  function openNotificationsModal() {
    openModal('modalNotifications');
  }

  function showMemberEmergencyDialog() {
    playAlertSound();
    showToast('🚨 ઇમરજન્સી SOS સિગ્નલ ગેટ ૧ સિક્યુરિટી અને એડમિનને મોકલાયો!', 'danger');
  }

  function sendWatchmanSOS() {
    playAlertSound();
    showToast('🚨 ગેટ ૧ પરથી ઇમરજન્સી સાયરન વગાડાયો! તમામ સભ્યોને એલર્ટ મોકલાયો.', 'danger');
  }

  function showWatchmanStaffSheet() {
    showToast('📞 હેલ્પલાઇન & કેમ્પસ સ્ટાફ: ગીતાબેન (મેઇડ) • કાળુભાઈ (દૂધવાળા)', 'info');
  }

  function showWatchmanManageSheet() {
    showToast('👮 વોચમેન સ્ટાફ: રમણભાઈ પરમાર (ગેટ ૧ - ઓન ડ્યુટી)', 'info');
  }

  function showEmergencyContactsSheet() {
    showToast('🚨 ઇમરજન્સી: પોલીસ ૧૦૦ • ફાયર ૧૦૧ • એમ્બ્યુલન્સ ૧૦૮ • લિફ્ટ 9825000000', 'warning');
  }

  function showAppealsModal() {
    pushScreen('sa-appeal-detail', 'અપીલ સમીક્ષા: શિવ શક્તિ એન્ક્લેવ');
  }

  // ==========================================================================
  // SCENARIO WORKFLOW RUNNER
  // ==========================================================================
  function runScenario(flowKey) {
    if (flowKey === 'visitor_flow') {
      switchRole('watchman');
      showToast('પગલું ૧: વોચમેન ગેટ પરથી ફ્લેટ A-402 ને રિંગ કરે છે...', 'info');
      setTimeout(() => triggerVisitorAlert(), 900);
    } else if (flowKey === 'upi_flow') {
      switchRole('member');
      switchMemberTab(2); // Bills Tab
      showToast('પગલું ૧: સભ્ય ૦% ફી UPI થી મેન્ટેનન્સ ભરે છે...', 'info');
      setTimeout(() => openUpiPaymentModal(), 600);
    } else if (flowKey === 'open_drawer') {
      openDrawer();
      showToast('AppNavigationDrawer સ્લાઇડ થયો! શોર્ટકટ્સ ચેક કરો.', 'info');
    } else if (flowKey === 'wrong_parking') {
      switchRole('watchman');
      openModal('modalVehicleLookup');
      showToast('વાહન સર્ચ: ગાડી નંબરથી ફ્લેટ માલિક શોધો...', 'info');
    }
  }

  // ==========================================================================
  // DATA RENDERING
  // ==========================================================================
  function renderRecentMembers() {
    const container = document.getElementById('adminRecentMembersList');
    const dirContainer = document.getElementById('adminMembersDirList');
    if (container) {
      container.innerHTML = state.members.slice(0, 4).map(m => `
        <div class="member-dir-item">
          <div class="mem-left">
            <span class="flat-tag">${m.flat}</span>
            <div><strong>${m.name}</strong><span class="phone-text">${m.phone}</span></div>
          </div>
          <span class="badge-tag">${m.type}</span>
        </div>
      `).join('');
    }
    if (dirContainer) {
      dirContainer.innerHTML = state.members.map(m => `
        <div class="member-dir-item">
          <div class="mem-left">
            <span class="flat-tag">${m.flat}</span>
            <div><strong>${m.name}</strong><span class="phone-text">${m.phone}</span></div>
          </div>
          <span class="badge-tag">${m.type}</span>
        </div>
      `).join('');
    }
  }

  function renderMemberVisitors() {
    const container = document.getElementById('memberVisitorsStreamList');
    const fullContainer = document.getElementById('memberFullVisitorsList');
    if (!container && !fullContainer) return;

    let list = state.visitors;
    if (state.currentVisitorScope === 'my_flat') {
      list = list.filter(v => v.flat === 'A-402');
    }
    if (state.currentStatusFilter !== 'all') {
      list = list.filter(v => v.status === state.currentStatusFilter);
    }

    const html = list.map(v => `
      <div class="visitor-card-item">
        <img src="${v.photo}" alt="${v.name}" class="visitor-thumb">
        <div class="visitor-meta">
          <strong>${v.name}</strong>
          <span>${v.purpose}</span>
          <span class="time-text">${v.time} • ફ્લેટ ${v.flat} • ${v.vehicle}</span>
        </div>
        <div class="visitor-card-actions">
          ${v.status === 'pending' ? `
            <button class="btn-xs-emerald" onclick="PrototypeApp.respondToVisitor(true)">✓ પ્રવેશ</button>
            <button class="btn-xs-outline" onclick="PrototypeApp.respondToVisitor(false)">✕ નકારો</button>
          ` : `
            <span class="badge-approved">${v.status.toUpperCase()}</span>
          `}
        </div>
      </div>
    `).join('');

    if (container) container.innerHTML = html;
    if (fullContainer) fullContainer.innerHTML = html;
  }

  function renderLiveGateFeed() {
    const container = document.getElementById('adminLiveGateFeed');
    if (!container) return;
    container.innerHTML = state.visitors.map(v => `
      <div class="feed-item-row">
        <img src="${v.photo}" class="feed-thumb" alt="${v.name}">
        <div class="feed-info">
          <strong>${v.name} ➔ ${v.flat}</strong>
          <span>${v.purpose} • ${v.time}</span>
        </div>
        <span class="badge-approved">${v.status}</span>
      </div>
    `).join('');
  }

  function renderWatchmanLogs() {
    const container = document.getElementById('watchmanHistoryList');
    if (!container) return;
    container.innerHTML = state.visitors.map(v => `
      <div class="watchman-log-card">
        <img src="${v.photo}" class="w-thumb" alt="${v.name}">
        <div class="w-log-meta">
          <strong>${v.name} (ફ્લેટ ${v.flat})</strong>
          <span>${v.purpose} • વાહન: ${v.vehicle}</span>
          <span class="w-time">સમય: ${v.time} • ગેટ ૧</span>
        </div>
        <button class="btn-checkout" onclick="PrototypeApp.showToast('વિઝિટર બહાર નીકળ્યાનું નોંધાયું!', 'info')">બહાર ગયા</button>
      </div>
    `).join('');
  }

  function renderSuperAdminData() {
    const socContainer = document.getElementById('saSocietiesList');
    if (socContainer) {
      socContainer.innerHTML = state.societies.map(s => `
        <div class="sa-soc-card">
          <div class="sa-soc-head">
            <strong>${s.name} (${s.city})</strong>
            <span class="badge-tag">${s.arch}</span>
          </div>
          <p>એડમિન: <strong>${s.admin}</strong> • કુલ એકમો: <strong>${s.units}</strong></p>
          <div class="sa-soc-status">સ્ટેટસ: <strong class="${s.status.includes('Pending') ? 'text-amber' : 'text-emerald'}">${s.status}</strong></div>
        </div>
      `).join('');
    }

    const userContainer = document.getElementById('saUsersList');
    if (userContainer) {
      userContainer.innerHTML = `
        <div class="sa-user-item"><div><strong>હરેશભાઈ પટેલ</strong><span>ચેરમેન / એડમિન • શ્રી શ્યામ રેસીડેન્સી</span></div><span class="badge-approved">ADMIN</span></div>
        <div class="sa-user-item"><div><strong>રાજેશભાઈ પટેલ</strong><span>સભ્ય • ફ્લેટ A-402</span></div><span class="badge-tag">MEMBER</span></div>
        <div class="sa-user-item"><div><strong>રમણભાઈ પરમાર</strong><span>સિક્યુરિટી ગાર્ડ • ગેટ ૧</span></div><span class="badge-tag">WATCHMAN</span></div>
      `;
    }
  }

  function renderPatrolSteps() {
    const container = document.getElementById('adminPatrolSteps');
    const watchmanCont = document.getElementById('watchmanPatrolSteps');
    const html = state.patrolRoute.map(step => `
      <div class="patrol-step-item">
        <span class="step-dot ${step.status === 'done' ? 'done' : 'pending'}"></span>
        <div class="step-meta">
          <strong>${step.name}</strong>
          <span>${step.time} • ${step.gps}</span>
        </div>
        <span class="step-badge ${step.status}">${step.status === 'done' ? 'VERIFIED' : 'PENDING'}</span>
      </div>
    `).join('');
    if (container) container.innerHTML = html;
    if (watchmanCont) watchmanCont.innerHTML = html;
  }

  function applyLanguage(lang) {
    state.currentLang = lang;
    const selector = document.getElementById('languageSelector');
    if (selector) selector.value = lang;
    showToast(`ભાષા: ${lang === 'gu' ? 'ગુજરાતી' : (lang === 'en' ? 'English' : 'हिन्दी')}`, 'info');
  }

  function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    if (!container) return;
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    const icon = type === 'success' ? '✓' : (type === 'danger' || type === 'warning' ? '⚠️' : 'ℹ️');
    toast.innerHTML = `<span>${icon}</span> <span>${message}</span>`;
    container.appendChild(toast);
    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(10px)';
      setTimeout(() => toast.remove(), 250);
    }, 3200);
  }

  function resetAllData() {
    state.maintenancePaid = false;
    state.pollVoted = false;
    state.pollVotes = { yes: 33, no: 9 };
    const payBtn = document.getElementById('btnMemPayUpi');
    const receiptBtn = document.getElementById('btnMemViewReceipt');
    if (payBtn) payBtn.style.display = 'inline-flex';
    if (receiptBtn) receiptBtn.style.display = 'none';
    switchRole('admin');
    showToast('પ્રોટોટાઇપ ડેટા સફળતાપૂર્વક રીસેટ થયો!', 'info');
  }

  // ==========================================================================
  // 1-CLICK INTERACTIVE SHOWCASE WALKTHROUGH
  // Runs the complete end-to-end security cycle in 8 seconds:
  // Watchman Logs Visitor -> Member Gets Ringing Popup -> Approves -> Gate Opens
  // ==========================================================================
  let isDemoRunning = false;
  function runInteractiveDemoFlow() {
    if (isDemoRunning) return;
    isDemoRunning = true;
    showToast('🚀 ૧-ક્લિક લાઈવ ડેમો શરૂ થઈ રહ્યો છે...', 'info');

    // Step 1: Switch to Watchman Terminal
    setTimeout(() => {
      switchRole('watchman');
      showToast('૧/૪: વોચમેન ટર્મિનલ: ગેટ ૧ પર ઝોમેટો ડિલિવરી બોય આવ્યો', 'info');
      playTone(523.25, 'triangle', 0.2);

      // Step 2: Auto-fill Form and Request Approval
      setTimeout(() => {
        const nameInput = document.getElementById('wmVisitorName');
        const phoneInput = document.getElementById('wmVisitorPhone');
        const flatSelect = document.getElementById('wmVisitorFlat');
        if (nameInput) nameInput.value = 'રાકેશ (Zomato)';
        if (phoneInput) phoneInput.value = '9876543210';
        if (flatSelect) flatSelect.value = 'A-402';
        showToast('૨/૪: ફ્લેટ A-402 ને તાત્કાલિક વેરિફિકેશન રિક્વેસ્ટ મોકલાઈ!', 'warning');
        playTone(659.25, 'sine', 0.25);

        // Step 3: Switch to Member screen and ring the approval dialog
        setTimeout(() => {
          switchRole('member');
          triggerVisitorAlert('રાકેશ (Zomato)', 'A-402', 'ખોરાક ડિલિવરી', '🛵');
          showToast('૩/૪: સભ્ય A-402 ના ફોન પર લાઈવ રિંગ વાગી!', 'warning');

          // Step 4: Member approves after 2.4s
          setTimeout(() => {
            respondToVisitor('approve');
            showToast('૪/૪: સભ્ય દ્વારા પ્રવેશ મંજૂર કરાયો! ✓', 'success');

            // Step 5: Switch back to Watchman to show Gate Open
            setTimeout(() => {
              switchRole('watchman');
              switchWatchmanTab('history');
              showToast('✨ સંપૂર્ણ લાઈવ ડેમો સફળ! ગેટ ૧ ખૂલી ગયો.', 'success');
              isDemoRunning = false;
            }, 1800);

          }, 2400);

        }, 1600);

      }, 1500);

    }, 400);
  }

  // Initialize
  function init() {
    setInterval(() => {
      const now = new Date();
      let hours = now.getHours();
      const mins = String(now.getMinutes()).padStart(2, '0');
      hours = hours % 12 || 12;
      const clock = document.getElementById('statusClock');
      if (clock) clock.innerText = `${hours}:${mins}`;
    }, 1000);

    const btnMobile = document.getElementById('btnViewMobile');
    const btnDesktop = document.getElementById('btnViewDesktop');
    const container = document.getElementById('deviceContainer');
    if (btnMobile && btnDesktop && container) {
      btnMobile.addEventListener('click', () => {
        btnMobile.classList.add('active');
        btnDesktop.classList.remove('active');
        container.classList.remove('desktop-view');
        showToast('📱 મોબાઈલ ફ્રેમ વ્યુ', 'info');
      });
      btnDesktop.addEventListener('click', () => {
        btnDesktop.classList.add('active');
        btnMobile.classList.remove('active');
        container.classList.add('desktop-view');
        showToast('💻 ડેસ્કટોપ વ્યુ', 'info');
      });
    }

    const btnAudio = document.getElementById('btnAudioToggle');
    if (btnAudio) {
      btnAudio.addEventListener('click', () => {
        state.isAudioEnabled = !state.isAudioEnabled;
        btnAudio.innerText = state.isAudioEnabled ? '🔊' : '🔇';
        showToast(state.isAudioEnabled ? 'સાઉન્ડ ચાલુ કર્યો' : 'સાઉન્ડ બંધ કર્યો', 'info');
      });
    }

    // Global Keyboard Presentation Shortcuts
    document.addEventListener('keydown', (e) => {
      const activeTag = document.activeElement ? document.activeElement.tagName.toLowerCase() : '';
      if (activeTag === 'input' || activeTag === 'textarea' || activeTag === 'select') {
        if (e.key === 'Escape') {
          document.activeElement.blur();
        }
        return;
      }

      if (e.key === '1') {
        switchRole('admin');
      } else if (e.key === '2') {
        switchRole('member');
      } else if (e.key === '3') {
        switchRole('watchman');
      } else if (e.key === '4') {
        switchRole('super_admin');
      } else if (e.key === 'd' || e.key === 'D') {
        runInteractiveDemoFlow();
      } else if (e.key === 'p' || e.key === 'P') {
        openUpiPaymentModal();
      } else if (e.key === 's' || e.key === 'S') {
        showMemberEmergencyDialog();
      } else if (e.key === 'Escape') {
        closeDrawer();
        document.querySelectorAll('.modal-overlay.active').forEach(m => m.classList.remove('active'));
      } else if (e.key === 'Backspace' && navigationStack.length > 0) {
        popNavigation();
      }
    });

    renderRecentMembers();
    renderMemberVisitors();
    renderLiveGateFeed();
    renderWatchmanLogs();
    renderSuperAdminData();
    renderPatrolSteps();
    switchRole('admin');
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  return {
    switchRole,
    pushScreen,
    popNavigation,
    openDrawer,
    closeDrawer,
    drawerAction,
    triggerAppBarAction,
    switchAdminTab,
    switchMemberTab,
    switchWatchmanTab,
    switchWatchmanBottomTab,
    switchSuperAdminTab,
    switchVisitorScope,
    filterVisitorsByStatus,
    openModal,
    closeModal,
    triggerVisitorAlert,
    respondToVisitor,
    quickTagVisitor,
    shuffleVisitorPhoto,
    openUpiPaymentModal,
    simulateUpiAppPay,
    confirmUpiPayment,
    showReceiptModal,
    showAccountsPdfModal,
    castVote,
    sendWrongParkingNotification,
    simulateValidQrScan,
    generatePreApprovePass,
    submitComplaint,
    resolveComplaint,
    submitNewMember,
    submitPublishNotice,
    submitNewPoll,
    triggerBulkBillAlert,
    approvePendingUtr,
    onboardNewSocietySubmit,
    sendGlobalBroadcast,
    simulatePatrolScan,
    openNoticeModal,
    openNotificationsModal,
    showMemberEmergencyDialog,
    sendWatchmanSOS,
    showWatchmanStaffSheet,
    showWatchmanManageSheet,
    showEmergencyContactsSheet,
    showAppealsModal,
    runScenario,
    runInteractiveDemoFlow,
    applyLanguage,
    showToast,
    resetAllData
  };
})();

// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/day_record.dart';
import '../services/firebase_service.dart';
import '../services/group_service.dart';
import '../viewmodels/providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/page_title.dart';
import '../widgets/screen_layout.dart';
import '../widgets/section_header.dart';
import '../widgets/settings_rows.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(stepSharingSyncProvider);
    final firebase = ref.watch(firebaseAvailableProvider);
    return firebase.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _FirebaseUnavailable(),
      data: (available) {
        if (!available) return const _FirebaseUnavailable();
        final auth = ref.watch(authStateProvider);
        return auth.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorPanel(message: 'Account error: $error'),
          data: (user) => user == null
              ? const _AuthenticationPanel()
              : _SignedInGroups(user: user),
        );
      },
    );
  }
}

class _FirebaseUnavailable extends StatelessWidget {
  const _FirebaseUnavailable();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant);
    return ScreenList(
      children: [
        const PageTitle(
          title: 'Groups',
          subtitle: 'Friends and live step counts',
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cloud_off_rounded, size: 28, color: colors.primary),
              const SizedBox(height: 12),
              Text('Firebase setup needed', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Your step tracker is still working locally. To enable sign-in and private groups, set up a Firebase project, enable Email/Password Authentication and Cloud Firestore, then provide the Android Firebase options described in README.md.',
                style: muted,
              ),
              const SizedBox(height: 12),
              Text(
                'No account or cloud data is created until you configure Firebase. Age, height, weight, gender, step history, distance and calories are not sent to Firebase.',
                style: muted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthenticationPanel extends StatefulWidget {
  const _AuthenticationPanel();

  @override
  State<_AuthenticationPanel> createState() => _AuthenticationPanelState();
}

class _AuthenticationPanelState extends State<_AuthenticationPanel> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  String _authError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account already uses that email. Sign in instead.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'weak-password':
          return 'Choose a stronger password (at least 6 characters).';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password was not recognized.';
        case 'network-request-failed':
          return 'Could not reach Firebase. Check your connection and try again.';
      }
    }
    return 'Could not ${_registering ? 'create the account' : 'sign in'}: $error';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    if (_registering && _password.text.length < 6) {
      setState(() => _error = 'Choose a password with at least 6 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = AuthService();
      if (_registering) {
        await service.register(
          email: _email.text,
          password: _password.text,
          displayName: _displayName.text,
        );
      } else {
        await service.signIn(email: _email.text, password: _password.text);
      }
    } catch (error) {
      if (mounted) setState(() => _error = _authError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ScreenList(
      children: [
        const PageTitle(
          title: 'Groups',
          subtitle: 'Friends and live step counts',
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _registering ? 'Create your Stride account' : 'Sign in to your groups',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Use an account to create private groups or join friends. Your local step history remains on this device.',
                style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (_registering) ...[
                TextField(
                  controller: _displayName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Display name (optional)',
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) {
                  if (!_busy) _submit();
                },
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: textTheme.bodySmall?.copyWith(color: colors.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_registering ? 'Create account' : 'Sign in'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _registering = !_registering;
                          _error = null;
                        }),
                child: Text(
                  _registering
                      ? 'Already have an account? Sign in'
                      : 'New here? Create an account',
                ),
              ),
            ],
          ),
        ),
        Text(
          'Your Settings name is your display name in private groups. Until you set one, Stride uses the name entered during registration. Only after you opt in will members see today\u2019s step total and last-updated time.',
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SignedInGroups extends ConsumerWidget {
  const _SignedInGroups({required this.user});

  final User user;

  String _displayName(WidgetRef ref) {
    final profileName = ref.read(profileProvider).name.trim();
    if (profileName.isNotEmpty) return profileName;
    final accountName = user.displayName?.trim() ?? '';
    return accountName.isEmpty ? 'Stride member' : accountName;
  }

  Future<void> _createGroup(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create a group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Group name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    try {
      final group = await ref.read(groupServiceProvider).createGroup(
            uid: user.uid,
            displayName: _displayName(ref),
            name: name,
          );
      ref.invalidate(myGroupsProvider(user.uid));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created ${group.name}. Invite friends to join.')),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, 'Could not create the group: $error');
    }
  }

  Future<void> _joinGroup(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join a group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 22,
          decoration: const InputDecoration(
            labelText: 'Invite code',
            helperText: 'Ask a group member for their private code.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Join')),
        ],
      ),
    );
    controller.dispose();
    if (code == null || !context.mounted) return;
    try {
      final group = await ref.read(groupServiceProvider).joinByInvite(
            uid: user.uid,
            displayName: _displayName(ref),
            code: code,
          );
      ref.invalidate(myGroupsProvider(user.uid));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You joined ${group.name}.')),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, 'Could not join the group: $error');
    }
  }

  Future<void> _setSharing(BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share today’s steps?'),
          content: const Text(
            'Members of your private groups will be able to see only your step total for today and when it was last updated. Your age, height, weight, gender, step history, distance, calories and daily goal are not shared.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Share today’s steps')),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    try {
      final service = ref.read(groupServiceProvider);
      await service.setSharingEnabled(user.uid, enabled);
      ref.invalidate(sharingOptInProvider(user.uid));
      if (enabled) {
        final record = ref.read(todayRecordProvider).valueOrNull;
        if (record != null) {
          await service.publishTodaySteps(uid: user.uid, record: record);
        }
      }
    } catch (error) {
      if (!enabled) ref.invalidate(sharingOptInProvider(user.uid));
      if (context.mounted) _showError(context, 'Could not update step sharing: $error');
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(groupServiceProvider).setSharingEnabled(user.uid, false);
    } catch (error) {
      ref.invalidate(sharingOptInProvider(user.uid));
      if (context.mounted) {
        _showError(
          context,
          'Sharing is off on this device, but the cloud total could not be removed. Reconnect and try signing out again. ($error)',
        );
      }
      return;
    }
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (error) {
      if (context.mounted) _showError(context, 'Could not sign out: $error');
    }
  }

  Future<void> _createInvite(
    BuildContext context,
    WidgetRef ref,
    GroupSummary group,
  ) async {
    try {
      final code = await ref.read(groupServiceProvider).createInvite(
            groupId: group.id,
            creatorUid: user.uid,
          );
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Invite to ${group.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share this private code with the friend you want to invite. It expires in 7 days.'),
              const SizedBox(height: 16),
              SelectableText(
                code,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied.')),
                );
              },
              child: const Text('Copy code'),
            ),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      );
    } catch (error) {
      if (context.mounted) _showError(context, 'Could not create an invite: $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(myGroupsProvider(user.uid));
    final sharing = ref.watch(sharingOptInProvider(user.uid));
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant);
    return ScreenList(
      children: [
        PageTitle(
          title: 'Groups',
          subtitle: user.email ?? user.displayName ?? 'Signed in',
          trailing: IconButton(
            tooltip: 'Sign out',
            onPressed: () => _signOut(context, ref),
            icon: const Icon(Icons.logout_rounded),
          ),
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Step sharing', large: true),
              sharing.when(
                loading: () => Text('Loading your privacy setting\u2026', style: muted),
                error: (error, _) => Text(
                  'Step sharing setting unavailable: $error',
                  style: textTheme.bodySmall?.copyWith(color: colors.error),
                ),
                data: (enabled) => ToggleRow(
                  title: 'Share today\u2019s steps',
                  subtitle: enabled
                      ? 'Sharing only today\u2019s total and its update time with group members.'
                      : 'Off. Your steps are not visible to group members.',
                  value: enabled,
                  onChanged: (value) => _setSharing(context, ref, value),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Your Settings name is shown to private-group members. Age, height, weight, gender, step history, distance, calories and goals stay on this device. Turning sharing off removes your shared step count from every group.',
                style: muted,
              ),
            ],
          ),
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Your groups', large: true),
              groups.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text(
                  'Could not load your groups: $error',
                  style: textTheme.bodyMedium?.copyWith(color: colors.error),
                ),
                data: (items) => items.isEmpty
                    ? Text(
                        'Create a private group or join a friend with an invite code.',
                        style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                      )
                    : Column(
                        children: [
                          for (final group in items)
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => GroupDetailScreen(group: group, currentUid: user.uid),
                                ),
                              ),
                              onLongPress: () => _createInvite(context, ref, group),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: colors.primaryContainer,
                                      foregroundColor: colors.onPrimaryContainer,
                                      child: Text(
                                        group.name.isEmpty
                                            ? '?'
                                            : String.fromCharCode(group.name.runes.first).toUpperCase(),
                                        style: textTheme.titleMedium?.copyWith(color: colors.onPrimaryContainer),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(group.name, style: textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                          Text('Private \u00b7 members only', style: muted),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _createGroup(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _joinGroup(context, ref),
                      icon: const Icon(Icons.key_rounded),
                      label: const Text('Join'),
                    ),
                  ),
                ],
              ),
              if (groups.valueOrNull?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  'Open a group to see members. Long-press a group or open it to create an invite.',
                  style: muted,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({required this.group, required this.currentUid, super.key});

  final GroupSummary group;
  final String currentUid;

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    try {
      final code = await ref.read(groupServiceProvider).createInvite(
            groupId: group.id,
            creatorUid: currentUid,
          );
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Private invite code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Anyone with this code can request to join until it expires in 7 days.'),
              const SizedBox(height: 14),
              SelectableText(code, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code copied.')));
              },
              child: const Text('Copy'),
            ),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      );
    } catch (error) {
      if (context.mounted) _showError(context, 'Could not create an invite: $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(groupMembersProvider(group.id));
    final sharedSteps = ref.watch(groupSharedStepsProvider(group.id));
    final todayKey = DayRecord.dateKeyFor(DateTime.now());
    final stepsByUid = <String, SharedStepCount>{
      for (final item in sharedSteps.valueOrNull ?? const <SharedStepCount>[])
        if (item.updatedAt != null &&
            DayRecord.dateKeyFor(item.updatedAt!.toLocal()) == todayKey)
          item.uid: item,
    };
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant);

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            tooltip: 'Invite a friend',
            onPressed: () => _invite(context, ref),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: ScreenList(
        topPadding: 8,
        bottomClearance: 28,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton(
                  onPressed: () => _invite(context, ref),
                  child: const Text('Invite friends'),
                ),
                const SizedBox(height: 8),
                Text(group.name, style: textTheme.headlineMedium),
                Text(
                  '${members.valueOrNull?.length ?? 0} members \u00b7 Private',
                  style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.lock_rounded, size: 18, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only group members can view the roster and opted-in step totals.',
                        style: muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(title: 'Today', large: true, padding: EdgeInsets.zero),
                Text(DateFormat('EEEE, d MMMM').format(DateTime.now()), style: muted),
                sharedSteps.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(minHeight: 4),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('Could not load shared steps: $error',
                        style: textTheme.bodySmall?.copyWith(color: colors.error)),
                  ),
                  data: (_) => const SizedBox.shrink(),
                ),
                members.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('Could not load members: $error',
                        style: textTheme.bodyMedium?.copyWith(color: colors.error)),
                  ),
                  data: (items) {
                    // Leaderboard order: shared totals first, highest steps on top.
                    final sorted = [...items]..sort((a, b) {
                        final sa = stepsByUid[a.uid]?.steps ?? -1;
                        final sb = stepsByUid[b.uid]?.steps ?? -1;
                        if (sa != sb) return sb.compareTo(sa);
                        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
                      });
                    return Column(
                      children: [
                        for (var i = 0; i < sorted.length; i++)
                          _MemberRow(
                            rank: i + 1,
                            member: sorted[i],
                            shared: stepsByUid[sorted[i].uid],
                            self: sorted[i].uid == currentUid,
                            subtitle: _stepSubtitle(stepsByUid[sorted[i].uid]),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Text(
            'A member who has not opted in, or whose total has not been updated today, appears as \u201cNot shared today.\u201d',
            style: muted,
          ),
        ],
      ),
    );
  }

  Widget _stepSubtitle(SharedStepCount? shared) {
    if (shared == null) return const Text('Not shared today');
    final at = shared.updatedAt;
    return Text(at == null ? 'Updated today' : 'Updated ${DateFormat.jm().format(at.toLocal())}');
  }
}

/// One leaderboard row, styled like Flowstate's weekly board: rank, avatar
/// (gold/silver/bronze ring for the top three sharers), name and today's
/// total; the signed-in member's row is highlighted.
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.rank,
    required this.member,
    required this.shared,
    required this.self,
    required this.subtitle,
  });

  final int rank;
  final GroupMember member;
  final SharedStepCount? shared;
  final bool self;
  final Widget subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ring = shared == null
        ? null
        : switch (rank) {
            1 => const Color(0xFFFFC107),
            2 => const Color(0xFFB0BEC5),
            3 => const Color(0xFFB87333),
            _ => null,
          };
    final initial = member.displayName.isEmpty
        ? '?'
        : String.fromCharCode(member.displayName.runes.first).toUpperCase();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: self ? const EdgeInsets.all(6) : EdgeInsets.zero,
      decoration: self
          ? BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              semanticsLabel: 'Rank $rank',
              style: textTheme.titleMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: ring == null ? null : Border.all(color: ring, width: 2),
            ),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: Text(initial),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${member.displayName}${self ? ' \u00b7 You' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                DefaultTextStyle.merge(
                  style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  child: subtitle,
                ),
              ],
            ),
          ),
          if (shared != null)
            Text(
              NumberFormat.decimalPattern().format(shared!.steps),
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            )
          else
            Icon(Icons.visibility_off_rounded, size: 20, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => ScreenList(
        children: [
          const PageTitle(title: 'Groups'),
          GlassCard(
            child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      );
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

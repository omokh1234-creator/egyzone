import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../core/services/admin_service.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  bool _isLoading = true;
  List<dynamic> _users = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await AdminService.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
      }
    }
  }

  Future<void> _banUser(int id, bool currentStatus) async {
    try {
      final success = await AdminService.banUser(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ban status updated')),
        );
        _fetchUsers(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update ban status: $e')),
        );
      }
    }
  }

  Future<void> _changeRole(int id, String newRole) async {
    try {
      final formattedRole = newRole.substring(0, 1).toUpperCase() + newRole.substring(1).toLowerCase();
      final success = await AdminService.updateUserRole(id, formattedRole);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User role updated to $formattedRole')),
        );
        _fetchUsers(); // Refresh list
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update role. Server rejected the request.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e')),
        );
      }
    }
  }

  void _showRoleDialog(int userId, String currentRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['admin', 'seller', 'customer'].map((role) {
            return RadioListTile<String>(
              title: Text(role.toUpperCase()),
              // ignore: deprecated_member_use
              value: role,
              // ignore: deprecated_member_use
              groupValue: currentRole.toLowerCase(),
              // ignore: deprecated_member_use
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null && value != currentRole.toLowerCase()) {
                  _changeRole(userId, value);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return 'Joined ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildAvatar(Map<String, dynamic> user, ColorScheme colorScheme, TextTheme textTheme) {
    final imgUrl = user['profilePicture'] as String?;
    final name = user['fullName'] as String? ?? 'U';
    final initials = name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    
    if (imgUrl != null && imgUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(imgUrl),
        backgroundColor: colorScheme.primaryContainer,
      );
    }
    
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary.withValues(alpha: 0.8), colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'U',
          style: GoogleFonts.inter(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17.sp,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role, ColorScheme colorScheme) {
    Color bgColor;
    Color textColor;
    switch (role) {
      case 'ADMIN':
        bgColor = colorScheme.primary.withValues(alpha: 0.12);
        textColor = colorScheme.primary;
        break;
      case 'SELLER':
        bgColor = colorScheme.secondary.withValues(alpha: 0.12);
        textColor = colorScheme.secondary;
        break;
      default: // CUSTOMER
        bgColor = colorScheme.tertiary.withValues(alpha: 0.12);
        textColor = colorScheme.tertiary;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isBanned, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isBanned 
            ? colorScheme.error.withValues(alpha: 0.12)
            : colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBanned 
              ? colorScheme.error.withValues(alpha: 0.2)
              : colorScheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isBanned ? colorScheme.error : colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isBanned ? 'BANNED' : 'ACTIVE',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: isBanned ? colorScheme.error : colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    final filteredUsers = _users.where((u) {
      final name = (u['fullName'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.02),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 4.w),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.08), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 60, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No users found.', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchUsers,
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 4.h),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final userId = user['userId'] ?? user['id'] ?? 0;
                          final name = user['fullName'] ?? 'Unknown User';
                          final email = user['email'] ?? 'No email';
                          final role = (user['role'] ?? 'customer').toString().toUpperCase();
                          final phone = user['phoneNumber'] as String?;
                          final isActive = user['isActive'];
                          final isBanned = isActive == false || user['isBanned'] == true;
                          final verified = user['isEmailVerified'] == true;
                          final joinedDate = _formatDate(user['createdAt'] as String?);

                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isBanned 
                                    ? colorScheme.error.withValues(alpha: 0.15) 
                                    : colorScheme.outline.withValues(alpha: 0.08),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {},
                                  child: Padding(
                                    padding: EdgeInsets.all(4.w),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildAvatar(user, colorScheme, textTheme),
                                        SizedBox(width: 4.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 18.sp,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.1,
                                                        color: colorScheme.onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (verified) ...[
                                                    SizedBox(width: 1.w),
                                                    Icon(
                                                      Icons.verified_rounded, 
                                                      color: colorScheme.primary, 
                                                      size: 16,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              SizedBox(height: 0.4.h),
                                               Text(
                                                 email,
                                                 style: GoogleFonts.inter(
                                                   fontSize: 15.sp,
                                                   fontWeight: FontWeight.w500,
                                                   color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                                                   letterSpacing: 0.1,
                                                 ),
                                                 maxLines: 1,
                                                 overflow: TextOverflow.ellipsis,
                                               ),
                                              if (phone != null && phone.isNotEmpty) ...[
                                                SizedBox(height: 0.4.h),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.phone_iphone_rounded,
                                                      size: 14,
                                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                                    ),
                                                    SizedBox(width: 1.w),
                                                     Text(
                                                       phone,
                                                       style: GoogleFonts.inter(
                                                         fontSize: 14.sp,
                                                         fontWeight: FontWeight.w500,
                                                         color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                                                         letterSpacing: 0.1,
                                                       ),
                                                     ),
                                                  ],
                                                ),
                                              ],
                                              if (joinedDate.isNotEmpty) ...[
                                                SizedBox(height: 0.4.h),
                                                 Text(
                                                   joinedDate,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13.5.sp,
                                                      fontWeight: FontWeight.w600,
                                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                                                      letterSpacing: 0.2,
                                                    ),
                                                 ),
                                              ],
                                              SizedBox(height: 1.2.h),
                                              Row(
                                                children: [
                                                  _buildRoleBadge(role, colorScheme),
                                                  SizedBox(width: 2.w),
                                                  _buildStatusBadge(isBanned, colorScheme),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert_rounded,
                                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          onSelected: (value) {
                                            if (value == 'role') {
                                              _showRoleDialog(userId, user['role'] ?? 'customer');
                                            } else if (value == 'ban') {
                                              _banUser(userId, isBanned);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'role',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.shield_outlined, size: 20, color: colorScheme.onSurface),
                                                  const SizedBox(width: 8),
                                                  const Text('Change Role'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'ban',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isBanned ? Icons.gavel_rounded : Icons.block_rounded, 
                                                    size: 20, 
                                                    color: colorScheme.error,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    isBanned ? 'Unban User' : 'Ban User', 
                                                    style: TextStyle(color: colorScheme.error),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

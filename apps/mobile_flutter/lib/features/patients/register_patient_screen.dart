import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'package:core/core.dart';
import 'providers/patients_providers.dart';

class RegisterPatientScreen extends ConsumerStatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  ConsumerState<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends ConsumerState<RegisterPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _nationalityController = TextEditingController();

  // Contact
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneSecondaryController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  // Medical
  final _primaryDiagnosisController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _allergyController = TextEditingController();
  final _medicationController = TextEditingController();
  final _comorbidityController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  // Insurance
  final _insuranceProviderController = TextEditingController();
  final _insuranceIdController = TextEditingController();

  // Emergency Contact
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyEmailController = TextEditingController();

  // Dropdown values
  Gender? _selectedGender;
  BloodType _selectedBloodType = BloodType.unknown;
  MaritalStatus _selectedMaritalStatus = MaritalStatus.single;
  bool _emergencyIsPrimary = true;

  // Lists
  final List<String> _diagnoses = [];
  final List<String> _allergies = [];
  final List<String> _medications = [];
  final List<String> _comorbidities = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _nationalIdController.dispose();
    _nationalityController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _phoneSecondaryController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _primaryDiagnosisController.dispose();
    _diagnosisController.dispose();
    _allergyController.dispose();
    _medicationController.dispose();
    _comorbidityController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _insuranceProviderController.dispose();
    _insuranceIdController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.t('registerPatient')),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: AppResponsive(
          mobile: (_) => _buildForm(context, isTablet: false),
          tablet: (_) => _buildForm(context, isTablet: true),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool isTablet}) {
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(NeuroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            context: context,
            title: localizations.t('personalInfo'),
            icon: Icons.person,
            children: [
              if (isTablet)
                Row(
                  children: [
                    Expanded(child: _buildTextField(context, _firstNameController, localizations.t('firstName'), required: true)),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _buildTextField(context, _middleNameController, localizations.t('middleName'))),
                    Expanded(child: _buildTextField(context, _lastNameController, localizations.t('lastName'), required: true)),
                  ],
                )
              else ...[
                _buildTextField(context, _firstNameController, localizations.t('firstName'), required: true),
                _buildTextField(context, _middleNameController, localizations.t('middleName')),
                _buildTextField(context, _lastNameController, localizations.t('lastName'), required: true),
              ],
              if (isTablet)
                Row(
                  children: [
                    Expanded(child: _buildDateField(context, _dateOfBirthController, localizations.t('dateOfBirth'), required: true)),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _buildGenderDropdown(context)),
                  ],
                )
              else ...[
                _buildDateField(context, _dateOfBirthController, localizations.t('dateOfBirth'), required: true),
                _buildGenderDropdown(context),
              ],
              if (isTablet)
                Row(
                  children: [
                    Expanded(child: _buildTextField(context, _nationalityController, localizations.t('nationality'))),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _buildTextField(context, _nationalIdController, localizations.t('nationalId'))),
                  ],
                )
              else ...[
                _buildTextField(context, _nationalityController, localizations.t('nationality')),
                _buildTextField(context, _nationalIdController, localizations.t('nationalId')),
              ],
              if (isTablet)
                Row(
                  children: [
                    Expanded(child: _buildTextField(context, _weightController, localizations.t('weight'), keyboardType: TextInputType.number)),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _buildTextField(context, _heightController, localizations.t('height'), keyboardType: TextInputType.number)),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _buildBloodTypeDropdown(context)),
                  ],
                )
              else ...[
                Row(
                  children: [
                    Expanded(child: _buildTextField(context, _weightController, localizations.t('weight'), keyboardType: TextInputType.number)),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _buildTextField(context, _heightController, localizations.t('height'), keyboardType: TextInputType.number)),
                  ],
                ),
                _buildBloodTypeDropdown(context),
              ],
              _buildMaritalStatusDropdown(context),
            ],
          ),
          SizedBox(height: NeuroSpacing.lg),

          _buildSection(
            context: context,
            title: localizations.t('contactInfo'),
            icon: Icons.contact_mail,
            children: [
              if (isTablet)
                Row(
                  children: [
                    Expanded(child: _buildTextField(context, _emailController, localizations.t('email'), keyboardType: TextInputType.emailAddress)),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _buildTextField(context, _phoneController, localizations.t('phone'), keyboardType: TextInputType.phone)),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _buildTextField(context, _phoneSecondaryController, localizations.t('phoneSecondary'), keyboardType: TextInputType.phone)),
                  ],
                )
              else ...[
                _buildTextField(context, _emailController, localizations.t('email'), keyboardType: TextInputType.emailAddress),
                _buildTextField(context, _phoneController, localizations.t('phone'), keyboardType: TextInputType.phone),
                _buildTextField(context, _phoneSecondaryController, localizations.t('phoneSecondary'), keyboardType: TextInputType.phone),
              ],
              _buildTextField(context, _addressController, localizations.t('address')),
              if (isTablet)
                Row(
                  children: [
                    Expanded(child: _buildTextField(context, _cityController, localizations.t('city'))),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _buildTextField(context, _countryController, localizations.t('country'))),
                  ],
                )
              else ...[
                _buildTextField(context, _cityController, localizations.t('city')),
                _buildTextField(context, _countryController, localizations.t('country')),
              ],
            ],
          ),
          SizedBox(height: NeuroSpacing.lg),

          _buildSection(
            context: context,
            title: localizations.t('insurance'),
            icon: Icons.health_and_safety,
            children: [
              if (isTablet)
                Row(
                  children: [
                    Expanded(child: _buildTextField(context, _insuranceProviderController, localizations.t('provider'))),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _buildTextField(context, _insuranceIdController, localizations.t('insuranceId'))),
                  ],
                )
              else ...[
                _buildTextField(context, _insuranceProviderController, localizations.t('provider')),
                _buildTextField(context, _insuranceIdController, localizations.t('insuranceId')),
              ],
            ],
          ),
          SizedBox(height: NeuroSpacing.lg),

          _buildSection(
            context: context,
            title: localizations.t('medicalInfo'),
            icon: Icons.medical_services,
            children: [
              _buildTextField(context, _primaryDiagnosisController, localizations.t('primaryDiagnosis')),
              _buildTagField(context, _diagnosisController, _diagnoses, localizations.t('diagnoses')),
              _buildTagField(context, _allergyController, _allergies, localizations.t('allergies')),
              _buildTagField(context, _medicationController, _medications, localizations.t('medications')),
              _buildTagField(context, _comorbidityController, _comorbidities, localizations.t('comorbidities')),
            ],
          ),
          SizedBox(height: NeuroSpacing.lg),

          _buildSection(
            context: context,
            title: localizations.t('emergencyContact'),
            icon: Icons.emergency,
            children: [
              if (isTablet)
                Row(
                  children: [
                    Expanded(child: _buildTextField(context, _emergencyNameController, localizations.t('name'), required: true)),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _buildTextField(context, _emergencyRelationshipController, localizations.t('relationship'), required: true)),
                  ],
                )
              else ...[
                _buildTextField(context, _emergencyNameController, localizations.t('name'), required: true),
                _buildTextField(context, _emergencyRelationshipController, localizations.t('relationship'), required: true),
              ],
              if (isTablet)
                Row(
                  children: [
                    Expanded(child: _buildTextField(context, _emergencyPhoneController, localizations.t('phone'))),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _buildTextField(context, _emergencyEmailController, localizations.t('email'))),
                  ],
                )
              else ...[
                _buildTextField(context, _emergencyPhoneController, localizations.t('phone')),
                _buildTextField(context, _emergencyEmailController, localizations.t('email')),
              ],
              SwitchListTile(
                title: Text(localizations.t('primaryContact')),
                value: _emergencyIsPrimary,
                onChanged: (v) => setState(() => _emergencyIsPrimary = v),
              ),
            ],
          ),
          SizedBox(height: NeuroSpacing.xxl),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: AppButton(
              label: _isSubmitting ? localizations.t('registering') : localizations.t('registerPatient'),
              icon: _isSubmitting ? null : Icons.person_add,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitForm,
            ),
          ),
          SizedBox(height: NeuroSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: NeuroSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: NeuroSpacing.sm),
        AppCard(
          child: Padding(
            padding: EdgeInsets.all(NeuroSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
      child: AppInput(
        controller: controller,
        label: label,
        hint: required ? '$label *' : null,
        keyboardType: keyboardType,
        validator: required
            ? (v) => v == null || v.isEmpty ? '$label is required' : null
            : null,
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: NeuroSpacing.lg,
            vertical: NeuroSpacing.md,
          ),
        ),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            controller.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          }
        },
        validator: required
            ? (v) => v == null || v.isEmpty ? '$label is required' : null
            : null,
      ),
    );
  }

  Widget _buildGenderDropdown(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
      child: DropdownButtonFormField<Gender>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).t('gender'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: NeuroSpacing.md,
            vertical: NeuroSpacing.sm,
          ),
        ),
        items: Gender.values.map((g) => DropdownMenuItem(
          value: g,
          child: Text(g.name),
        )).toList(),
        onChanged: (v) => setState(() => _selectedGender = v),
      ),
    );
  }

  Widget _buildBloodTypeDropdown(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
      child: DropdownButtonFormField<BloodType>(
        value: _selectedBloodType,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).t('bloodType'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: NeuroSpacing.md,
            vertical: NeuroSpacing.sm,
          ),
        ),
        items: BloodType.values.map((b) => DropdownMenuItem(
          value: b,
          child: Text(b.name),
        )).toList(),
        onChanged: (v) => setState(() => _selectedBloodType = v!),
      ),
    );
  }

  Widget _buildMaritalStatusDropdown(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
      child: DropdownButtonFormField<MaritalStatus>(
        value: _selectedMaritalStatus,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).t('maritalStatus'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: NeuroSpacing.md,
            vertical: NeuroSpacing.sm,
          ),
        ),
        items: MaritalStatus.values.map((m) => DropdownMenuItem(
          value: m,
          child: Text(m.name),
        )).toList(),
        onChanged: (v) => setState(() { if (v != null) _selectedMaritalStatus = v; }),
      ),
    );
  }

  Widget _buildTagField(
    BuildContext context,
    TextEditingController controller,
    List<String> tags,
    String label,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(NeuroRadius.md),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: NeuroSpacing.lg,
                      vertical: NeuroSpacing.md,
                    ),
                  ),
                  onFieldSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      setState(() => tags.add(value.trim()));
                      controller.clear();
                    }
                  },
                ),
              ),
              SizedBox(width: NeuroSpacing.sm),
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    setState(() => tags.add(controller.text.trim()));
                    controller.clear();
                  }
                },
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            SizedBox(height: NeuroSpacing.xs),
            Wrap(
              spacing: NeuroSpacing.xs,
              runSpacing: NeuroSpacing.xs,
              children: tags.map((tag) => Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => tags.remove(tag)),
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select gender')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final patient = Patient(
      id: '',
      mrn: '',
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _dateOfBirthController.text.trim(),
      gender: _selectedGender!,
      nationality: _nationalityController.text.trim().isEmpty ? null : _nationalityController.text.trim(),
      nationalId: _nationalIdController.text.trim().isEmpty ? null : _nationalIdController.text.trim(),
      bloodType: _selectedBloodType,
      weight: double.tryParse(_weightController.text),
      height: double.tryParse(_heightController.text),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      phoneSecondary: _phoneSecondaryController.text.trim().isEmpty ? null : _phoneSecondaryController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
      maritalStatus: _selectedMaritalStatus,
      insuranceProvider: _insuranceProviderController.text.trim().isEmpty ? null : _insuranceProviderController.text.trim(),
      insuranceId: _insuranceIdController.text.trim().isEmpty ? null : _insuranceIdController.text.trim(),
      primaryDiagnosis: _primaryDiagnosisController.text.trim().isEmpty ? null : _primaryDiagnosisController.text.trim(),
      diagnoses: _diagnoses,
      allergies: _allergies,
      medications: _medications,
      comorbidities: _comorbidities,
      createdAt: now,
      updatedAt: now,
    );

    final useCase = ref.read(registerPatientProvider);
    final result = await useCase(patient);

    setState(() => _isSubmitting = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (createdPatient) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient registered successfully. MRN: ${createdPatient.mrn}')),
        );
        context.pushReplacement('/patients/${createdPatient.id}');
      },
    );
  }
}

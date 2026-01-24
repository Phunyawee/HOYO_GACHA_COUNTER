# ตรวจสอบก่อนว่าเคยโหลดไปหรือยัง (กัน Error เวลารันซ้ำ)
if (-not ([System.Management.Automation.PSTypeName]'DarkMenuRenderer').Type) {
    Add-Type -TypeDefinition @"
    using System.Windows.Forms;
    using System.Drawing;

    public class DarkMenuRenderer : ProfessionalColorTable {
        // 1. สีพื้นหลังตอนเอาเมาส์ชี้ (Hover)
        public override Color MenuItemSelected { get { return Color.FromArgb(65, 65, 65); } }
        public override Color MenuItemBorder { get { return Color.DimGray; } }

        // 2. สีพื้นหลังตอนคลิก (Pressed) - แก้จอขาว
        public override Color MenuItemPressedGradientBegin { get { return Color.FromArgb(45, 45, 48); } }
        public override Color MenuItemPressedGradientEnd { get { return Color.FromArgb(45, 45, 48); } }
        public override Color MenuBorder { get { return Color.DimGray; } }

        // 3. สีพื้นหลังตอนเลือก (Selected)
        public override Color MenuItemSelectedGradientBegin { get { return Color.FromArgb(65, 65, 65); } }
        public override Color MenuItemSelectedGradientEnd { get { return Color.FromArgb(65, 65, 65); } }

         // 4. แก้แถบซ้าย (Image Margin)
        public override Color ImageMarginGradientBegin { get { return Color.Black; } }
        public override Color ImageMarginGradientMiddle { get { return Color.Black; } }
        public override Color ImageMarginGradientEnd { get { return Color.Black; } }
        
        // 5. สีพื้นหลัง Dropdown
        public override Color ToolStripDropDownBackground { get { return Color.Black; } }
    }
"@ -ReferencedAssemblies System.Windows.Forms, System.Drawing
}
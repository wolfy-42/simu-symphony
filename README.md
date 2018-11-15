# SIMU - Simulation Environment for FPGA
As a design services company, at Fidus we have to be able to quickly simulate our FPGA, independent of the underlying OS or tool or FPGA vendor. 
- short setup time and the learning curve because we don't like wasting time.
- promote all good practices in the field of verification - regression, randomization, scalability, etc.
- flexible scripting structure to switch quickly between different OS, HDL languages and simulation tool vendors. 

# Features
- HDL supported - SystemVerilog, Verilog
- Simulation tools supported - Mentor ModelSim/Questa, Vivado XSim
- TCL based - works inside the tool (Modelsim/Quasta/Vivado) or in OS terminal (Linux/Windows) using the native/installed TCL interpreter 
- A preset template of a test-case, ready to be reused
- Code Coverage statistics reports
- Pass/Fail statistics per test-case and per regression run
- Automated regression executing all test-cases named with a with "tc_" prefix 
- Regression history accumulation
- Multithreaded regression runs for complex simulation environments, executing many test-cases in parallel, requiring one license per thread

# ToDo List
- HDL support for VHDL (almost complete), UVM, HLS
- Simulation tools support - Cadence Incisive, Aldec Riviera, Synopsys VCS
- submit jobs to remote machines









## Welcome to GitHub Pages

You can use the [editor on GitHub](https://github.com/FidusSystems/simu/edit/master/README.md) to maintain and preview the content for your website in Markdown files.

Whenever you commit to this repository, GitHub Pages will run [Jekyll](https://jekyllrb.com/) to rebuild the pages in your site, from the content in your Markdown files.

### Markdown

Markdown is a lightweight and easy-to-use syntax for styling your writing. It includes conventions for

```markdown
Syntax highlighted code block

# Header 1
## Header 2
### Header 3

- Bulleted
- List

1. Numbered
2. List

**Bold** and _Italic_ and `Code` text

[Link](url) and ![Image](src)
```

For more details see [GitHub Flavored Markdown](https://guides.github.com/features/mastering-markdown/).

### Jekyll Themes

Your Pages site will use the layout and styles from the Jekyll theme you have selected in your [repository settings](https://github.com/FidusSystems/simu/settings). The name of this theme is saved in the Jekyll `_config.yml` configuration file.

### Support or Contact

Having trouble with Pages? Check out our [documentation](https://help.github.com/categories/github-pages-basics/) or [contact support](https://github.com/contact) and we’ll help you sort it out.

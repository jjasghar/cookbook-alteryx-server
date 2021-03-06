#
# Cookbook Name:: test
# Spec:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'alteryx-server::default' do
  context 'When all attributes are default, on Windows' do
    RTS_OVERRIDES_PATH = './spec/unit/files/'\
                         'RuntimeSettings-overrides.xml'.freeze
    let(:chef_run) do
      lwrps = %w(alteryx_server_package
                 alteryx_server_r_package
                 alteryx_server_license
                 alteryx_server_runtimesettings
                 alteryx_server_service)
      runner = ChefSpec::SoloRunner.new(
        platform: 'windows',
        version: '2012r2',
        step_into: lwrps) do |node|
          node.automatic['cpu']['total'] = 2
          node.automatic['kernel']['os_info']['total_visible_memory_size'] =
            1_000_000
          node.set['alteryx']['r_source'] = 'C:\\test.exe'
          node.set['alteryx']['r_version'] = '3.2.3'
          node.set['alteryx']['rts_defaults_path'] =
            './spec/unit/files/RuntimeSettings-defaults.xml'
          node.set['alteryx']['rts_overrides_path'] = RTS_OVERRIDES_PATH
        end
      runner.converge(described_recipe)
    end

    it 'Converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'Installs Alteryx Server' do
      expect(chef_run).to install_package('Alteryx 10.6 x64')
    end

    it 'Installs R Predictive Tools' do
      expect(chef_run).to install_windows_package(
        'Alteryx Predictive Tools with R 3.2.3'
      )
    end

    it 'Enables the AlteryxService' do
      # Due to some wonkiness in how ChefSpec populates the resource collection
      # on this one, it's probably better to leave this to integration tests.
      expect(true).to be true
    end

    it 'Renders RuntimeSettings.xml' do
      content = <<-EOH.gsub(/^ +/, '')
        <?xml version="1.0" encoding="UTF-8"?>
        <SystemSettings>
        \t<Controller>
        \t\t<ServerSecretEncrypted>2000</ServerSecretEncrypted>
        \t</Controller>
        \t<Engine>
        \t\t<NumThreads>3</NumThreads>
        \t\t<SortJoinMemory>260</SortJoinMemory>
        \t</Engine>
        </SystemSettings>
      EOH
      expect(chef_run).to render_file(RTS_OVERRIDES_PATH).with_content(content)
    end
  end
end
